import Foundation
import EventKit
import SwiftUI
import Combine

class EventKitManager: ObservableObject {
    static let shared = EventKitManager()
    private let eventStore = EKEventStore()
    
    @Published var authorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    
    // Request permission to access the calendar
    func requestAccess(completion: @escaping (Bool, Error?) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                    completion(granted, error)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                    completion(granted, error)
                }
            }
        }
    }
    
    // Create an event in the default calendar
    func createEvent(title: String, startDate: Date, endDate: Date, location: String? = nil, notes: String? = nil, completion: @escaping (Bool, Error?) -> Void) {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .authorized, .fullAccess:
            self.saveEvent(title: title, startDate: startDate, endDate: endDate, location: location, notes: notes, completion: completion)
        case .notDetermined:
            requestAccess { granted, error in
                if granted {
                    self.saveEvent(title: title, startDate: startDate, endDate: endDate, location: location, notes: notes, completion: completion)
                } else {
                    completion(false, error)
                }
            }
        default:
            completion(false, NSError(domain: "EventKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Calendar access denied."]))
        }
    }
    
    private func saveEvent(title: String, startDate: Date, endDate: Date, location: String?, notes: String?, completion: @escaping (Bool, Error?) -> Void) {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.location = location
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            DispatchQueue.main.async {
                completion(true, nil)
            }
        } catch let error {
            DispatchQueue.main.async {
                completion(false, error)
            }
        }
    }
}


// MARK: - Document Manager
class DocumentManager: ObservableObject {
    static let shared = DocumentManager()
    
    @Published var documents: [AdvisoryDocument] = []
    
    private let fileManager = FileManager.default
    private let documentsFolder = "AdvisoryDocuments"
    private let metadataFile = "documents_metadata.json"
    
    private init() {
        createDirectoryIfNeeded()
        loadDocuments()
    }
    
    private var baseDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private var storageDirectory: URL {
        baseDirectory.appendingPathComponent(documentsFolder)
    }
    
    private var metadataURL: URL {
        storageDirectory.appendingPathComponent(metadataFile)
    }
    
    private func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: storageDirectory.path) {
            try? fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        }
    }
    
    func saveDocument(title: String, category: String, description: String, tags: [String], lawyerName: String, tempURL: URL) {
        let fileExtension = tempURL.pathExtension
        let fileName = "\(UUID().uuidString).\(fileExtension)"
        let destinationURL = storageDirectory.appendingPathComponent(fileName)
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: tempURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            try fileManager.copyItem(at: tempURL, to: destinationURL)
            
            var newDoc = AdvisoryDocument(
                title: title,
                description: description,
                category: category,
                tags: tags,
                lawyerName: lawyerName,
                date: formatDate(Date()),
                fileType: fileExtension.uppercased(),
                localFileName: fileName
            )
            newDoc.fileURL = destinationURL
            
            DispatchQueue.main.async {
                self.documents.append(newDoc)
            }
            persistMetadata()
        } catch {
            print("Failed to save document: \(error.localizedDescription)")
        }
    }
    
    func loadDocuments() {
        guard let data = try? Data(contentsOf: metadataURL) else { return }
        
        do {
            var decodedDocs = try JSONDecoder().decode([AdvisoryDocument].self, from: data)
            
            for i in 0..<decodedDocs.count {
                if let fileName = decodedDocs[i].localFileName {
                    let fullURL = storageDirectory.appendingPathComponent(fileName)
                    if FileManager.default.fileExists(atPath: fullURL.path) {
                        decodedDocs[i].fileURL = fullURL
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.documents = decodedDocs
            }
        } catch {
            print("Failed to decode metadata: \(error)")
        }
    }
    
    private func persistMetadata() {
        do {
            let data = try JSONEncoder().encode(documents)
            try data.write(to: metadataURL)
        } catch {
            print("Failed to encode metadata: \(error)")
        }
    }
    
    func deleteDocument(id: UUID) {
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        let doc = documents[index]
        
        if let fileName = doc.localFileName {
            let fileURL = storageDirectory.appendingPathComponent(fileName)
            try? fileManager.removeItem(at: fileURL)
        }
        
        documents.remove(at: index)
        persistMetadata()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: date)
    }
}
