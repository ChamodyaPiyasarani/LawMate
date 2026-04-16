import Foundation
import Combine
import LocalAuthentication
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

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
    
    func login(email: String, role: UserRole, profile: [String: String]? = nil) {
        Auth.auth().signIn(withEmail: email, password: "password123") { [weak self] result, error in
            if let _ = error {
                self?.registerUser(email: email, role: role, profile: profile)
            }
        }
    }
    
    private func registerUser(email: String, role: UserRole, profile: [String: String]? = nil) {
        Auth.auth().createUser(withEmail: email, password: "password123") { [weak self] result, error in
            if let user = result?.user {
                let newUser = User(
                    id: user.uid,
                    fullName: profile?["fullName"] ?? "New \(role.rawValue)",
                    email: email,
                    role: role,
                    phoneNumber: profile?["phone"] ?? "",
                    specialty: profile?["specialty"],
                    experience: profile?["experience"],
                    bio: profile?["bio"]
                )
                
                do {
                    try self?.db.collection("users").document(user.uid).setData(from: newUser)
                } catch {
                    print("Error saving user: \(error)")
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
