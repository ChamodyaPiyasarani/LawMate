import Foundation
import Combine
import LocalAuthentication
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import FirebaseStorage
import Security

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User? = nil
    @Published var isAuthenticated: Bool = false
    
    private let db = Firestore.firestore()
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        // Setup Firebase Listener
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            if let user = user {
                self.fetchUserProfile(uid: user.uid)
            } else {
                self.isAuthenticated = false
                self.currentUser = nil
                UserDefaults.standard.set(false, forKey: "isLoggedIn")
            }
        }
    }
    
    func updateFCMToken(_ token: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Only update if the token has actually changed to save on Firestore writes
        let lastToken = UserDefaults.standard.string(forKey: "lastFCMToken")
        if lastToken == token {
            print("FCM Token is already up to date.")
            return
        }
        
        db.collection("users").document(uid).updateData([
            "fcmToken": token
        ]) { error in
            if let error = error {
                print("Error updating FCM token: \(error)")
            } else {
                print("FCM Token successfully updated in Firestore.")
                UserDefaults.standard.set(token, forKey: "lastFCMToken")
            }
        }
    }

    func updateAPNSToken(_ token: Data) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        let lastToken = UserDefaults.standard.string(forKey: "lastAPNSToken")
        if lastToken == tokenString {
            print("APNs token is already up to date.")
            return
        }

        db.collection("users").document(uid).updateData([
            "apnsToken": tokenString
        ]) { error in
            if let error = error {
                print("Error updating APNs token: \(error)")
            } else {
                print("APNs token successfully updated in Firestore.")
                UserDefaults.standard.set(tokenString, forKey: "lastAPNSToken")
            }
        }
    }
    
    private func fetchUserProfile(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("DEBUG: Error fetching user document: \(error.localizedDescription)")
                return
            }
            
            guard let document = snapshot, document.exists else {
                print("DEBUG: User document does not exist for UID: \(uid)")
                return
            }
            
            do {
                var data = try document.data(as: User.self)
                data.id = document.documentID
                DispatchQueue.main.async {
                    self.currentUser = data
                    self.isAuthenticated = true
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    UserDefaults.standard.set(data.role.rawValue, forKey: "userRole")

                    self.ensureMessagingKey(userId: uid, existingKey: data.messagePublicKey)
                    
                    if let fcmToken = Messaging.messaging().fcmToken {
                        self.updateFCMToken(fcmToken)
                    }
                }
            } catch {
                print("DEBUG: User decoding error for UID \(uid): \(error)")
                let diagnosticCode = (error as? DecodingError) != nil ? "[38001]" : "[38002]"
                DispatchQueue.main.async {
                    ToastManager.shared.show(title: "Data Error \(diagnosticCode)", message: "We found an issue with your profile data structure. Please contact support.", type: .error)
                }
            }
        }
    }
    
    func uploadProfileImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let _ = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        // 1. Resize image to keep Base64 string small (Firestore has 1MB limit)
        let targetSize = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        // 2. Convert to Base64 (High compression)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.4) else {
            completion(.failure(NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])))
            return
        }
        
        let base64String = "data:image/jpeg;base64," + imageData.base64EncodedString()
        
        // 3. Store directly in Firestore
        self.updateUserProfile(profileImage: base64String) { success in
            if success {
                completion(.success(base64String))
            } else {
                completion(.failure(NSError(domain: "Auth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Database (500): Failed to save profile image data."])))
            }
        }
    }
    
    func updateUserProfile(fullName: String? = nil, phoneNumber: String? = nil, specialty: String? = nil, experience: String? = nil, bio: String? = nil, casesWon: String? = nil, profileImage: String? = nil, textScale: Double? = nil, highContrast: Bool? = nil, address: String? = nil, latitude: Double? = nil, longitude: Double? = nil, completion: ((Bool) -> Void)? = nil) {
        guard let uid = Auth.auth().currentUser?.uid else { 
            completion?(false)
            return 
        }
        
        var updateData: [String: Any] = [:]
        
        if let fullName = fullName { updateData["fullName"] = fullName }
        if let phoneNumber = phoneNumber { updateData["phoneNumber"] = phoneNumber }
        if let specialty = specialty { updateData["specialty"] = specialty }
        if let experience = experience { updateData["experience"] = experience }
        if let bio = bio { updateData["bio"] = bio }
        if let casesWon = casesWon { updateData["casesWon"] = casesWon }
        if let profileImage = profileImage { updateData["profileImage"] = profileImage }
        if let textScale = textScale { updateData["textScale"] = textScale }
        if let highContrast = highContrast { updateData["highContrast"] = highContrast }
        if let address = address { updateData["address"] = address }
        if let latitude = latitude { updateData["latitude"] = latitude }
        if let longitude = longitude { updateData["longitude"] = longitude }
        
        guard !updateData.isEmpty else { 
            completion?(true)
            return 
        }
        
        db.collection("users").document(uid).updateData(updateData) { [weak self] error in
            if let error = error {
                print("DEBUG: Error updating profile in Firestore: \(error.localizedDescription)")
                completion?(false)
            } else {
                print("DEBUG: Profile successfully updated in Firestore.")
                
                // Consistency Fix: Update user image in all their conversations, cases, and appointments
                if let profileImage = profileImage {
                    FirestoreManager.shared.updateUserImageInConversations(userId: uid, imageUrl: profileImage)
                    if let user = self?.currentUser {
                        FirestoreManager.shared.updateUserImageInCases(userId: uid, imageUrl: profileImage, role: user.role)
                        FirestoreManager.shared.updateUserImageInAppointments(userId: uid, imageUrl: profileImage, role: user.role)
                    }
                }
                
                if var user = self?.currentUser {
                    if let fullName = fullName { user.fullName = fullName }
                    if let phoneNumber = phoneNumber { user.phoneNumber = phoneNumber }
                    user.specialty = specialty ?? user.specialty
                    user.experience = experience ?? user.experience
                    user.bio = bio ?? user.bio
                    user.casesWon = casesWon ?? user.casesWon
                    if let profileImage = profileImage { user.profileImage = profileImage }
                    if let textScale = textScale { user.textScale = textScale }
                    if let highContrast = highContrast { user.highContrast = highContrast }
                    if let address = address { user.address = address }
                    if let latitude = latitude { user.latitude = latitude }
                    if let longitude = longitude { user.longitude = longitude }
                    
                    DispatchQueue.main.async {
                        self?.currentUser = user
                        completion?(true)
                    }
                } else {
                    completion?(true)
                }
            }
        }
    }
    
    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func signUp(email: String, role: UserRole, password: String, profile: [String: Any]? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let user = result?.user {
                let newUser = User(
                    id: user.uid,
                    fullName: profile?["fullName"] as? String ?? "New \(role.rawValue)",
                    email: email,
                    role: role,
                    phoneNumber: profile?["phone"] as? String ?? "",
                    specialty: profile?["specialty"] as? String,
                    experience: profile?["experience"] as? String,
                    bio: profile?["bio"] as? String,
                    casesWon: profile?["casesWon"] as? String,
                    messagePublicKey: MessageCryptoManager.shared.publicKeyBase64(),
                    password: password,
                    address: profile?["address"] as? String,
                    latitude: profile?["latitude"] as? Double,
                    longitude: profile?["longitude"] as? Double
                )
                
                do {
                    try self?.db.collection("users").document(user.uid).setData(from: newUser)
                    completion(.success(()))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    private func ensureMessagingKey(userId: String, existingKey: String?) {
        let localKey = MessageCryptoManager.shared.publicKeyBase64()
        guard existingKey != localKey else { return }

        db.collection("users").document(userId).updateData([
            "messagePublicKey": localKey
        ]) { error in
            if let error = error {
                print("Error updating message public key: \(error)")
            }
        }
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            self.isAuthenticated = false
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
            UserDefaults.standard.removeObject(forKey: "userRole")
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    func authenticateWithBiometrics(completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(false, "Biometrics not available.")
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Log in to LawMate") { success, evalError in
            DispatchQueue.main.async {
                if success {
                    completion(true, nil)
                } else {
                    completion(false, evalError?.localizedDescription ?? "Failed to authenticate.")
                }
            }
        }
    }
    
    // MARK: - Update Password
    func updatePassword(newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in."])))
            return
        }
        
        user.updatePassword(to: newPassword) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
