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
        db.collection("users").document(uid).getDocument { [weak self] (snapshot: DocumentSnapshot?, error: Error?) in
            guard let self = self else { return }
            guard let document = snapshot, document.exists, let data = try? document.data(as: User.self) else {
                return
            }
            DispatchQueue.main.async {
                self.currentUser = data
                self.isAuthenticated = true
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                UserDefaults.standard.set(data.role.rawValue, forKey: "userRole")
                
                // If we have a cached FCM token, ensure it's synced
                if let fcmToken = Messaging.messaging().fcmToken {
                    self.updateFCMToken(fcmToken)
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
        
        let storageRef = Storage.storage().reference().child("profile_images/\(uid).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { [weak self] _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let downloadURL = url?.absoluteString {
                    // Update user profile with new image URL
                    self?.updateUserProfile(profileImage: downloadURL)
                    completion(.success(downloadURL))
                }
            }
        }
    }
    
    func updateUserProfile(fullName: String? = nil, phoneNumber: String? = nil, specialty: String? = nil, experience: String? = nil, bio: String? = nil, profileImage: String? = nil, textScale: Double? = nil, highContrast: Bool? = nil) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        var updateData: [String: Any] = [:]
        
        if let fullName = fullName { updateData["fullName"] = fullName }
        if let phoneNumber = phoneNumber { updateData["phoneNumber"] = phoneNumber }
        if let specialty = specialty { updateData["specialty"] = specialty }
        if let experience = experience { updateData["experience"] = experience }
        if let bio = bio { updateData["bio"] = bio }
        if let profileImage = profileImage { updateData["profileImage"] = profileImage }
        if let textScale = textScale { updateData["textScale"] = textScale }
        if let highContrast = highContrast { updateData["highContrast"] = highContrast }
        
        guard !updateData.isEmpty else { return }
        
        db.collection("users").document(uid).updateData(updateData) { [weak self] error in
            if let error = error {
                print("Error updating profile: \(error)")
            } else {
                print("Profile successfully updated in Firestore.")
                if var user = self?.currentUser {
                    if let fullName = fullName { user.fullName = fullName }
                    if let phoneNumber = phoneNumber { user.phoneNumber = phoneNumber }
                    user.specialty = specialty ?? user.specialty
                    user.experience = experience ?? user.experience
                    user.bio = bio ?? user.bio
                    if let profileImage = profileImage { user.profileImage = profileImage }
                    if let textScale = textScale { user.textScale = textScale }
                    if let highContrast = highContrast { user.highContrast = highContrast }
                    DispatchQueue.main.async {
                        self?.currentUser = user
                    }
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
