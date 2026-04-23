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



