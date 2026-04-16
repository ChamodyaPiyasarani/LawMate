import Foundation
import CoreData

@objc(CDLegalCase)
public class CDLegalCase: NSManagedObject, Identifiable {
    @NSManaged public var id: String
    @NSManaged public var caseNumber: String
    @NSManaged public var title: String
    @NSManaged public var clientName: String
    @NSManaged public var lawyerName: String?
    @NSManaged public var type: String
    @NSManaged public var status: String
    @NSManaged public var priority: String
    @NSManaged public var createdDate: Date
    @NSManaged public var stagesData: Data?
    @NSManaged public var documents: NSSet?
}

// MARK: Generated accessors for documents
extension CDLegalCase {
    @objc(addDocumentsObject:)
    @NSManaged public func addToDocuments(_ value: CDDocument)

    @objc(removeDocumentsObject:)
    @NSManaged public func removeFromDocuments(_ value: CDDocument)

    @objc(addDocuments:)
    @NSManaged public func addToDocuments(_ values: NSSet)

    @objc(removeDocuments:)
    @NSManaged public func removeFromDocuments(_ values: NSSet)
}
