import Foundation
import SwiftUI

struct AdvisoryDocument: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let description: String
    let category: String
    let tags: [String]
    let lawyerName: String
    let date: String
    let fileType: String // "PDF", "DOCX", "Image"
    var fileURL: URL?
    var localFileName: String?
    
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

struct LegalCaseDocument: Identifiable, Codable, Hashable {
    var id = UUID()
    let fileName: String
    let fileType: String // "PDF", "JPG", etc.
    let uploadedAt: Date
    let uploadedStage: String 
    var localFileName: String?
    
    var iconName: String {
        switch fileType.uppercased() {
        case "PDF": return "doc.fill"
        case "JPG", "PNG", "HEIC": return "photo.fill"
        default: return "doc.text.fill"
        }
    }
}
