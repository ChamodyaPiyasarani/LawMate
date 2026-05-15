import Foundation
import CoreData

@objc(CDUser)
public class CDUser: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var fullName: String
    @NSManaged public var email: String
    @NSManaged public var role: String
    @NSManaged public var phoneNumber: String?
    @NSManaged public var profileImage: String?
}
