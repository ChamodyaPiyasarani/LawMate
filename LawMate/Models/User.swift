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

struct AdvisoryDocument: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let description: String
    let category: String
    let tags: [String]
    let lawyerName: String
    let date: String
    let fileType: String // "PDF", "DOCX", "Image"
    var fileURL: URL? // For runtime viewing
    var localFileName: String? // For persistence
    
    init(id: UUID = UUID(), 
         title: String, 
         description: String = "", 
         category: String, 
         tags: [String] = [], 
         lawyerName: String = "", 
         date: String, 
         fileType: String = "PDF",
         fileURL: URL? = nil,
         localFileName: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.tags = tags
        self.lawyerName = lawyerName
        self.date = date
        self.fileType = fileType
        self.fileURL = fileURL
        self.localFileName = localFileName
    }
}

// MARK: - Case Lifecycle Models

struct CaseStage: Identifiable, Codable, Hashable {
    var id = UUID()
    let title: String
    let description: String
    var date: Date?
    var isCompleted: Bool
    
    // Status color for the timeline
    var statusColor: Color {
        isCompleted ? .lmPrimary : .gray.opacity(0.3)
    }
}

struct LegalCaseDocument: Identifiable, Codable, Hashable {
    var id = UUID()
    let fileName: String
    let fileType: String // "PDF", "JPG", etc.
    let uploadedAt: Date
    let uploadedStage: String // Title of the CaseStage it belongs to
    var localFileName: String?
    
    var iconName: String {
        switch fileType.uppercased() {
        case "PDF": return "doc.fill"
        case "JPG", "PNG", "HEIC": return "photo.fill"
        default: return "doc.text.fill"
        }
    }
}

struct LegalCase: Identifiable, Hashable {
    let id: String
    let caseNumber: String
    let title: String
    let clientName: String
    let type: String
    var status: String
    let priority: String
    let lawyerName: String
    let createdDate: Date
    
    var stages: [CaseStage]
    var documents: [LegalCaseDocument]
    
    // Statistics for top cards
    var completedStagesCount: Int {
        stages.filter { $0.isCompleted }.count
    }
    
    var progressProgress: Double {
        guard !stages.isEmpty else { return 0 }
        return Double(completedStagesCount) / Double(stages.count)
    }
}

// MARK: - LegalCase Mock Data
extension LegalCase {
    static let mockStages: [CaseStage] = [
        CaseStage(title: "Created", description: "Case registered in system", date: Date().addingTimeInterval(-86400 * 5), isCompleted: true),
        CaseStage(title: "Assigned", description: "Lawyer assigned to case", date: Date().addingTimeInterval(-86400 * 4), isCompleted: true),
        CaseStage(title: "Consultation", description: "Initial meeting done", date: Date().addingTimeInterval(-86400 * 3), isCompleted: true),
        CaseStage(title: "Documents", description: "Evidence collected", date: Date().addingTimeInterval(-86400 * 2), isCompleted: true),
        CaseStage(title: "Preparation", description: "Legal preparation ongoing", date: Date(), isCompleted: false),
        CaseStage(title: "Filed", description: "Case submitted to court", isCompleted: false),
        CaseStage(title: "Hearings", description: "Court hearings ongoing", isCompleted: false),
        CaseStage(title: "Judgment", description: "Court decision received", isCompleted: false),
        CaseStage(title: "Closed", description: "Case finalized", isCompleted: false)
    ]
    
    static let mockDocs: [LegalCaseDocument] = [
        LegalCaseDocument(fileName: "Initial_Petition.pdf", fileType: "PDF", uploadedAt: Date().addingTimeInterval(-86400 * 4), uploadedStage: "Assigned"),
        LegalCaseDocument(fileName: "Evidence_Photo_01.jpg", fileType: "JPG", uploadedAt: Date().addingTimeInterval(-86400 * 2), uploadedStage: "Documents"),
        LegalCaseDocument(fileName: "Client_Notes.docx", fileType: "DOCX", uploadedAt: Date().addingTimeInterval(-86400 * 3), uploadedStage: "Consultation")
    ]
    
    static let mockCase = LegalCase(
        id: "1",
        caseNumber: "CLM-2024-001",
        title: "Divorce & Child Custody Case",
        clientName: "Sanduni Fernando",
        type: "Family Law",
        status: "Active",
        priority: "High",
        lawyerName: "Atty. John Doe",
        createdDate: Date().addingTimeInterval(-86400 * 5),
        stages: mockStages,
        documents: mockDocs
    )
}
