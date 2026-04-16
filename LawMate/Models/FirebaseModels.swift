import Foundation
import FirebaseFirestoreSwift

struct FBLegalCase: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var caseNumber: String
    var title: String
    var clientName: String
    var lawyerName: String
    var type: String
    var status: String
    var priority: String
    var createdDate: Date
    var stages: [FBCaseStage] = []
    
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
