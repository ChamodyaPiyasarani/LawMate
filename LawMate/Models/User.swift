import Foundation
import SwiftUI

enum UserRole: String, Codable {
    case none = "none"
    case client = "Client"
    case lawyer = "Lawyer"
}

struct User: Identifiable, Codable {
    var id: String
    var fullName: String
    var email: String
    var role: UserRole
    var profileImage: String?
    var phoneNumber: String
    
    // Lawyer specific optional fields
    var specialty: String?
    var experience: String?
    var bio: String?
    var fcmToken: String?
    
    // Accessibility Preferences
    var textScale: Double
    var highContrast: Bool
    
    // UI Preference / Testing
    var password: String?
    
    init(id: String, fullName: String, email: String, role: UserRole, profileImage: String? = nil, phoneNumber: String = "", specialty: String? = nil, experience: String? = nil, bio: String? = nil, fcmToken: String? = nil, textScale: Double = 1.0, highContrast: Bool = false, password: String? = nil) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.role = role
        self.profileImage = profileImage
        self.phoneNumber = phoneNumber
        self.specialty = specialty
        self.experience = experience
        self.bio = bio
        self.fcmToken = fcmToken
        self.textScale = textScale
        self.highContrast = highContrast
        self.password = password
    }
}

// Mock data for current user
extension User {
    static let mockClient = User(
        id: "mock-client",
        fullName: "Chamodya Piyasarani",
        email: "chamo@example.com",
        role: .client,
        profileImage: "client_profile",
        phoneNumber: "+94 77 123 4567"
    )
    
    static let mockLawyer = User(
        id: "mock-lawyer",
        fullName: "Atty. John Doe",
        email: "john@lawmate.com",
        role: .lawyer,
        profileImage: "lawyer_profile",
        phoneNumber: "+94 71 987 6543"
    )
}


// MARK: - Legacy definitions moved to individual files
