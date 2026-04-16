import Foundation
import CoreData

@objc(CDDocument)
public class CDDocument: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var fileName: String
    @NSManaged public var fileType: String
    @NSManaged public var uploadedAt: Date
    @NSManaged public var localFileName: String?
    @NSManaged public var legalCase: CDLegalCase?
}
