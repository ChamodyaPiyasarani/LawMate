import Foundation
import FirebaseFirestoreSwift

struct FBLegalCase: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var caseNumber: String
    var title: String
    var clientName: String
    var clientId: String // Linked client ID
    var clientImage: String? // Linked client profile image
    var lawyerName: String
    var lawyerId: String // Linked lawyer ID
    var lawyerImage: String? // Linked lawyer profile image
    var type: String
    var status: String
    var priority: String
    var createdDate: Date? // Optional to prevent decoding failures if missing in Firestore
    var stages: [FBCaseStage] = []
    var documents: [FBDocument]? = nil
    
    var wrappedDocuments: [FBDocument] {
        documents ?? []
    }
    
    // Hashable conformance for navigation routing
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: FBLegalCase, rhs: FBLegalCase) -> Bool { lhs.id == rhs.id }
    
    // Helper properties mapping what CDLegalCase did
    var completedStagesCount: Int {
        stages.filter { $0.isCompleted }.count
    }
    
    var progressProgress: Double {
        guard !stages.isEmpty else { return 0 }
        return Double(completedStagesCount) / Double(stages.count)
    }
}

struct FBCaseStage: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var isCompleted: Bool
    var date: Date?
}

struct FBDocument: Identifiable, Codable {
    @DocumentID var id: String?
    var legalCaseId: String
    var fileName: String
    var fileType: String
    var uploadedAt: Date
    var localFileName: String?
}

struct FBConversation: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var participants: [String] // Array of user UIDs
    var lastMessage: String?
    var lastMessageAt: Date?
    var memberNames: [String: String]? // [UID: Name] for easy display
    var memberImages: [String: String?]? // [UID: ImageURL?] for easy display
    
    // Helper to get the other participant's info
    func partnerInfo(for currentUserId: String) -> (id: String, name: String, image: String?) {
        let partnerId = participants.first(where: { $0 != currentUserId }) ?? "Unknown"
        let name = memberNames?[partnerId] ?? "User"
        let image = memberImages?[partnerId] ?? nil
        return (partnerId, name, image)
    }
}

struct FBMessage: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var senderId: String
    var text: String
    var timestamp: Date
}
