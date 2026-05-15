import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    private final class BundleLocator {}

    static func loadModel() -> NSManagedObjectModel {
        let candidateBundles = [Bundle.main, Bundle(for: BundleLocator.self)]
        for bundle in candidateBundles {
            if let modelURL = bundle.url(forResource: "LawMate", withExtension: "momd"),
               let model = NSManagedObjectModel(contentsOf: modelURL) {
                return model
            }
        }

        if let merged = NSManagedObjectModel.mergedModel(from: candidateBundles) {
            return merged
        }

        fatalError("Failed to load LawMate Core Data model")
    }

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Add mock data for preview if needed
        let newUser = CDUser(context: viewContext)
        newUser.id = UUID()
        newUser.fullName = "John Preview"
        newUser.email = "john@example.com"
        newUser.role = "Lawyer"
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "LawMate", managedObjectModel: Self.loadModel())
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
