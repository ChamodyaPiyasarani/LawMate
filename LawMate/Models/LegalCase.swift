import Foundation
import SwiftUI

struct CaseStage: Identifiable, Codable, Hashable {
    var id = UUID()
    let title: String
    let description: String
    var date: Date?
    var isCompleted: Bool
    
    var statusColor: Color {
        isCompleted ? Color("lmPrimary") : Color.gray.opacity(0.3)
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
    
    var completedStagesCount: Int {
        stages.filter { $0.isCompleted }.count
    }
    
    var progressProgress: Double {
        guard !stages.isEmpty else { return 0 }
        return Double(completedStagesCount) / Double(stages.count)
    }
}

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
