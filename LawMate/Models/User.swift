import Foundation
import SwiftUI

enum UserRole: String, Codable {
    case none = "none"
    case client = "Client"
    case lawyer = "Lawyer"
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            let rawValue = try container.decode(String.self)
            switch rawValue.lowercased() {
            case "client": self = .client
            case "lawyer": self = .lawyer
            case "none": self = .none
            default: self = .none
            }
        } catch {
            self = .none
        }
    }
}


struct User: Identifiable, Codable, Hashable {
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
    var casesWon: String?
    var fcmToken: String?
    var apnsToken: String?
    var messagePublicKey: String?
    var rating: Double?
    var reviewCount: Int?
    
    // Accessibility Preferences
    var textScale: Double?
    var highContrast: Bool?

    
    // Location Information
    var address: String?
    var latitude: Double?
    var longitude: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, fullName, email, role, profileImage, phoneNumber
        case specialty, experience, bio, casesWon, fcmToken, apnsToken, messagePublicKey, textScale, highContrast
        case address, latitude, longitude, rating, reviewCount
    }
    
    init(id: String, fullName: String, email: String, role: UserRole, profileImage: String? = nil, phoneNumber: String = "", specialty: String? = nil, experience: String? = nil, bio: String? = nil, casesWon: String? = nil, fcmToken: String? = nil, apnsToken: String? = nil, messagePublicKey: String? = nil, textScale: Double = 1.0, highContrast: Bool = false, address: String? = nil, latitude: Double? = nil, longitude: Double? = nil, rating: Double? = nil, reviewCount: Int? = nil) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.role = role
        self.profileImage = profileImage
        self.phoneNumber = phoneNumber
        self.specialty = specialty
        self.experience = experience
        self.bio = bio
        self.casesWon = casesWon
        self.fcmToken = fcmToken
        self.apnsToken = apnsToken
        self.messagePublicKey = messagePublicKey
        self.textScale = textScale
        self.highContrast = highContrast
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.rating = rating
        self.reviewCount = reviewCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        fullName = try container.decode(String.self, forKey: .fullName)
        email = (try? container.decode(String.self, forKey: .email)) ?? ""
        role = (try? container.decode(UserRole.self, forKey: .role)) ?? .none
        phoneNumber = (try? container.decode(String.self, forKey: .phoneNumber)) ?? ""
        
        // Flexible decoding for profileImage (handle String or Map)
        if let directString = try? container.decode(String.self, forKey: .profileImage) {
            profileImage = directString
        } else if let dict = try? container.decode([String: String].self, forKey: .profileImage), let url = dict["url"] {
            profileImage = url
        } else {
            profileImage = nil
        }
        
        specialty = try? container.decode(String.self, forKey: .specialty)
        experience = try? container.decode(String.self, forKey: .experience)
        bio = try? container.decode(String.self, forKey: .bio)
        casesWon = try? container.decode(String.self, forKey: .casesWon)
        fcmToken = try? container.decode(String.self, forKey: .fcmToken)
        apnsToken = try? container.decode(String.self, forKey: .apnsToken)
        messagePublicKey = try? container.decode(String.self, forKey: .messagePublicKey)
        textScale = (try? container.decode(Double.self, forKey: .textScale)) ?? 1.0
        highContrast = (try? container.decode(Bool.self, forKey: .highContrast)) ?? false
        address = try? container.decode(String.self, forKey: .address)
        latitude = try? container.decode(Double.self, forKey: .latitude)
        longitude = try? container.decode(Double.self, forKey: .longitude)
        rating = try? container.decode(Double.self, forKey: .rating)
        reviewCount = try? container.decode(Int.self, forKey: .reviewCount)
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
