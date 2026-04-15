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

// MARK: - EventKitService
class EventKitService: ObservableObject {
    static let shared = EventKitService()
    let eventStore = EKEventStore()
    
    @Published var isAuthorized = false
    
    private init() {
        checkPermission()
    }
    
    func checkPermission() {
        let status = EKEventStore.authorizationStatus(for: .event)
        DispatchQueue.main.async {
            self.isAuthorized = (status == .authorized || status == .fullAccess)
        }
    }
    
    func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    completion(granted)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    completion(granted)
                }
            }
        }
    }
    
    func fetchEvents(for date: Date) -> [EKEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )
        
        return eventStore.events(matching: predicate)
    }
    
    func fetchEventsForMonth(date: Date) -> [Date: [EKEvent]] {
        let calendar = Calendar.current
        guard let monthRange = calendar.range(of: .day, in: .month, for: date),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return [:]
        }
        
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        
        let predicate = eventStore.predicateForEvents(
            withStart: startOfMonth,
            end: endOfMonth,
            calendars: nil
        )
        
        let allEvents = eventStore.events(matching: predicate)
        
        var eventsByDay: [Date: [EKEvent]] = [:]
        for event in allEvents {
            let day = calendar.startOfDay(for: event.startDate)
            if eventsByDay[day] != nil {
                eventsByDay[day]?.append(event)
            } else {
                eventsByDay[day] = [event]
            }
        }
        
        return eventsByDay
    }
    
    func addEvent(title: String, type: String, date: Date, completion: @escaping (Result<Bool, Error>) -> Void) {
        let events = fetchEvents(for: date)
        
        if events.count >= 3 {
             completion(.failure(NSError(domain: "EventKitService", code: 403, userInfo: [NSLocalizedDescriptionKey: "Maximum of 3 events allowed per day."])))
            return
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = "[\(type)] \(title)"
        event.startDate = date
        event.endDate = date.addingTimeInterval(3600) // 1 hour duration
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        event.notes = "Type: \(type)"
        
        do {
            try eventStore.save(event, span: .thisEvent)
            completion(.success(true))
        } catch {
            completion(.failure(error))
        }
    }
}

// MARK: - CalendarViewModel
// MARK: - CalendarViewModel
class CalendarViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var currentMonth: Date = Date()
    @Published var eventsForSelectedDate: [EKEvent] = []
    @Published var monthEventsMap: [Date: [EKEvent]] = [:]
    @Published var isAuthorized = false
    @Published var errorMessage: String? = nil
    
    private let service = EventKitService.shared
    private var cancellables = Set<AnyCancellable>()
    private let eventStore = EKEventStore() // Used only for creating mock instances
    
    init() {
        service.$isAuthorized
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authorized in
                self?.isAuthorized = authorized
                self?.refreshMonthData()
                self?.refreshSelectedDateEvents()
            }
            .store(in: &cancellables)
            
        // Initial refresh
        refreshMonthData()
        refreshSelectedDateEvents()
    }
    
    func requestAccess() {
        service.requestAccess { [weak self] granted in
            self?.refreshMonthData()
            self?.refreshSelectedDateEvents()
        }
    }
    
    private var mockEvents: [EKEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let e1 = EKEvent(eventStore: eventStore)
        e1.title = "[Appointment] Client Interview: Case #405"
        e1.startDate = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today)!
        e1.endDate = e1.startDate.addingTimeInterval(3600)
        e1.notes = "Discuss initial evidence."
        
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let e2 = EKEvent(eventStore: eventStore)
        e2.title = "[Hearing] State vs. Silva - Preliminary"
        e2.startDate = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: tomorrow)!
        e2.endDate = e2.startDate.addingTimeInterval(7200)
        e2.notes = "High Court, Room 04"
        
        let e3 = EKEvent(eventStore: eventStore)
        e3.title = "[Hearing] Case #102: Cross Examination"
        e3.startDate = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: tomorrow)!
        e3.endDate = e3.startDate.addingTimeInterval(3600)
        
        let e4 = EKEvent(eventStore: eventStore)
        e4.title = "[Appointment] Legal Research: Case #405"
        e4.startDate = calendar.date(bySettingHour: 15, minute: 30, second: 0, of: tomorrow)!
        e4.endDate = e4.startDate.addingTimeInterval(3600)
        
        let nextWeek = calendar.date(byAdding: .day, value: 3, to: today)!
        
        let e5 = EKEvent(eventStore: eventStore)
        e5.title = "[Consultation] Property Deed Review"
        e5.startDate = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: nextWeek)!
        e5.endDate = e5.startDate.addingTimeInterval(1800)
        
        let e6 = EKEvent(eventStore: eventStore)
        e6.title = "[Hearing] Family Court: Case #05"
        e6.startDate = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: nextWeek)!
        e6.endDate = e6.startDate.addingTimeInterval(3600)
        
        return [e1, e2, e3, e4, e5, e6]
    }
    
    func refreshMonthData() {
        var realEvents: [Date: [EKEvent]] = [:]
        if isAuthorized {
            realEvents = service.fetchEventsForMonth(date: currentMonth)
        }
        
        // Merge mock events
        var combined = realEvents
        let calendar = Calendar.current
        for event in mockEvents {
            let day = calendar.startOfDay(for: event.startDate)
            let monthCheck = calendar.isDate(day, equalTo: currentMonth, toGranularity: .month)
            if monthCheck {
                if combined[day] != nil {
                    combined[day]?.append(event)
                } else {
                    combined[day] = [event]
                }
            }
        }
        monthEventsMap = combined
    }
    
    func refreshSelectedDateEvents() {
        var realEvents: [EKEvent] = []
        if isAuthorized {
            realEvents = service.fetchEvents(for: selectedDate)
        }
        
        // Merge mock events
        let calendar = Calendar.current
        let matchingMock = mockEvents.filter { calendar.isDate($0.startDate, inSameDayAs: selectedDate) }
        
        eventsForSelectedDate = (realEvents + matchingMock).sorted { $0.startDate < $1.startDate }
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
        refreshSelectedDateEvents()
    }
    
    func nextMonth() {
        if let next = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = next
            refreshMonthData()
        }
    }
    
    func previousMonth() {
        if let prev = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = prev
            refreshMonthData()
        }
    }
    
    func addEvent(title: String, type: String) {
        service.addEvent(title: title, type: type, date: selectedDate) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.refreshMonthData()
                    self?.refreshSelectedDateEvents()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func getColor(for date: Date) -> Color {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let count = monthEventsMap[day]?.count ?? 0
        
        if count == 0 {
            return .clear
        } else if count < 3 {
            return .yellow.opacity(0.3)
        } else {
            return Color.lmPrimary 
        }
    }
    
    func getStatusColor(for date: Date) -> Color {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let count = monthEventsMap[day]?.count ?? 0
        
        if count == 0 {
            return .clear
        } else if count < 3 {
            return .orange
        } else {
            return .white
        }
    }
    
    func getTextColor(for date: Date) -> Color {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let count = monthEventsMap[day]?.count ?? 0
        
        if count >= 3 {
            return .white
        } else {
            return .lmPrimary
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
