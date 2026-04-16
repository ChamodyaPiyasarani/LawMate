import Foundation
import Combine
import LocalAuthentication

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User? = nil
    @Published var isAuthenticated: Bool = false
    
    // In a real app, this would check a token or keychain
    init() {
        // Mocking an initial state check
        let isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        if isLoggedIn {
            // Restore session logic would go here
            self.isAuthenticated = true
            // Load mock user for now
            self.currentUser = User.mockClient 
        }
    }
    
    func login(email: String, role: UserRole) {
        // Real auth logic would go here (Firebase/CloudKit)
        self.currentUser = (role == .lawyer) ? User.mockLawyer : User.mockClient
        self.isAuthenticated = true
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(role.rawValue, forKey: "userRole")
    }
    
    func logout() {
        self.currentUser = nil
        self.isAuthenticated = false
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "userRole")
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
                    // Logic to find which user was last logged in or generic login
                    completion(true, nil)
                } else {
                    completion(false, evalError?.localizedDescription ?? "Failed to authenticate.")
                }
            }
        }
    }
}
