import XCTest
import CoreData
@testable import LawMate

final class CoreDataTests: XCTestCase {
    
    var persistentContainer: NSPersistentContainer!
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        // Use an in-memory store for testing
        persistentContainer = NSPersistentContainer(name: "LawMate")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { description, error in
            XCTAssertNil(error, "Failed to load in-memory persistent store: \(error?.localizedDescription ?? "")")
        }
        
        context = persistentContainer.viewContext
    }

    override func tearDown() {
        context = nil
        persistentContainer = nil
        super.tearDown()
    }

    func testCaseCreationAndPersistence() {
        // Create a test case
        let newCase = CDLegalCase(context: context)
        newCase.id = UUID().uuidString
        newCase.caseNumber = "TEST-001"
        newCase.title = "Core Data Test Case"
        newCase.clientName = "Jane Doe"
        newCase.lawyerName = "John Smith"
        newCase.type = "Civil Law"
        newCase.status = "Active"
        newCase.priority = "High"
        newCase.createdDate = Date()
        
        // Add a mock document
        let doc = CDDocument(context: context)
        doc.id = UUID()
        doc.fileName = "Test_Evidence.pdf"
        doc.fileType = "PDF"
        doc.uploadedAt = Date()
        doc.legalCase = newCase
        
        // Add stages via extension property
        newCase.stages = [
            CaseStage(title: "Filed", description: "Case was filed", isCompleted: true)
        ]
        
        // Save
        XCTAssertNoThrow(try context.save(), "Failed to save Core Data context")
        
        // Fetch
        let fetchRequest: NSFetchRequest<CDLegalCase> = NSFetchRequest(entityName: "CDLegalCase")
        fetchRequest.predicate = NSPredicate(format: "caseNumber == %@", "TEST-001")
        
        do {
            let fetchedCases = try context.fetch(fetchRequest)
            XCTAssertEqual(fetchedCases.count, 1)
            
            let fetchedCase = fetchedCases.first!
            XCTAssertEqual(fetchedCase.title, "Core Data Test Case")
            XCTAssertEqual(fetchedCase.wrappedDocuments.count, 1)
            XCTAssertEqual(fetchedCase.wrappedDocuments.first?.fileName, "Test_Evidence.pdf")
            XCTAssertEqual(fetchedCase.stages.count, 1)
            XCTAssertTrue(fetchedCase.stages.first?.isCompleted ?? false)
            
        } catch {
            XCTFail("Failed to fetch cases: \(error.localizedDescription)")
        }
    }
}
