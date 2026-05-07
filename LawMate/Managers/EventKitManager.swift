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
        
        let hasAccess: Bool
        if #available(iOS 17.0, *) {
            hasAccess = (status == .fullAccess)
        } else {
            hasAccess = (status == .authorized)
        }
        
        if hasAccess {
            self.saveEvent(title: title, startDate: startDate, endDate: endDate, location: location, notes: notes, completion: completion)
        } else if status == .notDetermined {
            requestAccess { granted, error in
                if granted {
                    self.saveEvent(title: title, startDate: startDate, endDate: endDate, location: location, notes: notes, completion: completion)
                } else {
                    completion(false, error)
                }
            }
        } else {
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
    
    // Remove an event from the default calendar
    func removeEvent(title: String, startDate: Date) {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        // Handle iOS 17+ and legacy authorization
        let hasAccess: Bool
        if #available(iOS 17.0, *) {
            hasAccess = (status == .fullAccess)
        } else {
            hasAccess = (status == .authorized)
        }
        
        guard hasAccess else { return }
        
        // Find events in a small window around the start date
        let predicate = eventStore.predicateForEvents(withStart: startDate.addingTimeInterval(-60), 
                                                     end: startDate.addingTimeInterval(60), 
                                                     calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        // Match by title
        let eventToDelete = events.first { $0.title.contains(title) || title.contains($0.title) }
        
        if let event = eventToDelete {
            do {
                try eventStore.remove(event, span: .thisEvent)
            } catch {
                print("Error removing event: \(error)")
            }
        }
    }
}



