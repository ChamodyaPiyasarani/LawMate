import Foundation
import SwiftUI



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
