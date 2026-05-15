import Foundation
import CoreData
import SwiftUI

extension CDLegalCase {
    var wrappedDocuments: [CDDocument] {
        let set = documents as? Set<CDDocument> ?? []
        return set.sorted { $0.uploadedAt < $1.uploadedAt }
    }
    
    var stages: [CaseStage] {
        get {
            guard let data = stagesData,
                  let decoded = try? JSONDecoder().decode([CaseStage].self, from: data) else {
                return LegalCase.mockStages
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                stagesData = encoded
            }
        }
    }
    
    var completedStagesCount: Int {
        stages.filter { $0.isCompleted }.count
    }
    
    var progressProgress: Double {
        guard !stages.isEmpty else { return 0 }
        return Double(completedStagesCount) / Double(stages.count)
    }
}
