import Foundation
import Combine
import LocalAuthentication
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseMessaging
import FirebaseStorage

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
        
        db.collection("users").document(uid).updateData([
            "fcmToken": token
        ]) { error in
            if let error = error {
                print("Error updating FCM token: \(error)")
            } else {
                print("FCM Token successfully updated in Firestore.")
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
                let data = try document.data(as: User.self)
                DispatchQueue.main.async {
                    self.currentUser = data
                    self.isAuthenticated = true
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    UserDefaults.standard.set(data.role.rawValue, forKey: "userRole")
                    
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
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            completion(.failure(NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])))
            return
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference().child("profile_images").child("\(uid).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { [weak self] _, error in
            if let error = error as NSError? {
                let message = self?.mapStorageError(error) ?? error.localizedDescription
                let detailedMessage = "Storage (\(error.code)): \(message)"
                print("DEBUG: \(detailedMessage)")
                completion(.failure(NSError(domain: "Storage", code: error.code, userInfo: [NSLocalizedDescriptionKey: detailedMessage])))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error as NSError? {
                    let message = self?.mapStorageError(error) ?? error.localizedDescription
                    let detailedMessage = "Storage (\(error.code)): \(message)"
                    print("DEBUG: \(detailedMessage)")
                    completion(.failure(NSError(domain: "Storage", code: error.code, userInfo: [NSLocalizedDescriptionKey: detailedMessage])))
                    return
                }
                
                if let downloadURL = url?.absoluteString {
                    self?.updateUserProfile(profileImage: downloadURL) { success in
                        if success {
                            completion(.success(downloadURL))
                        } else {
                            completion(.failure(NSError(domain: "Auth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Database (500): Profile uploaded, but database update failed."])))
                        }
                    }
                }
            }
        }
    }
    
    private func mapStorageError(_ error: NSError) -> String {
        switch error.code {
        case 18001, -13021: return "[\(error.code)] The image file or storage bucket was not found. Please ensure Storage is set up in Firebase."
        case 18006, -13010: return "[\(error.code)] Permissions denied. Check your Firebase Storage security rules."
        case 18005: return "[\(error.code)] User is not authenticated."
        case 18004: return "[\(error.code)] Storage quota exceeded. Please check your billing plan."
        case -13000: return "[\(error.code)] An unknown storage error occurred."
        default: return "[\(error.code)] \(error.localizedDescription)"
        }
    }
    
    func updateUserProfile(fullName: String? = nil, phoneNumber: String? = nil, specialty: String? = nil, experience: String? = nil, bio: String? = nil, casesWon: String? = nil, profileImage: String? = nil, textScale: Double? = nil, highContrast: Bool? = nil, completion: ((Bool) -> Void)? = nil) {
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
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func signUp(email: String, role: UserRole, password: String, profile: [String: String]? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let user = result?.user {
                let newUser = User(
                    id: user.uid,
                    fullName: profile?["fullName"] ?? "New \(role.rawValue)",
                    email: email,
                    role: role,
                    phoneNumber: profile?["phone"] ?? "",
                    specialty: profile?["specialty"],
                    experience: profile?["experience"],
                    bio: profile?["bio"],
                    casesWon: profile?["casesWon"],
                    password: password
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
}
