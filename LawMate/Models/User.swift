import Foundation
import SwiftUI

enum UserRole: String, Codable {
    case none = "none"
    case client = "Client"
    case lawyer = "Lawyer"
}

struct User: Identifiable, Codable {
    let id: UUID
    var fullName: String
    var email: String
    var role: UserRole
    var profileImage: String?
    var phoneNumber: String
    
    init(id: UUID = UUID(), fullName: String, email: String, role: UserRole, profileImage: String? = nil, phoneNumber: String = "") {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.role = role
        self.profileImage = profileImage
        self.phoneNumber = phoneNumber
    }
}

// Mock data for current user
extension User {
    static let mockClient = User(
        fullName: "Chamodya Piyasarani",
        email: "chamo@example.com",
        role: .client,
        profileImage: "client_profile",
        phoneNumber: "+94 77 123 4567"
    )
    
    static let mockLawyer = User(
        fullName: "Atty. John Doe",
        email: "john@lawmate.com",
        role: .lawyer,
        profileImage: "lawyer_profile",
        phoneNumber: "+94 71 987 6543"
    )
}


// MARK: - Legacy definitions moved to individual files
