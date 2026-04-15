import Foundation
import EventKit
import SwiftUI

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
        
        // Add specific type to notes for filtering or display
        event.notes = "Type: \(type)"
        
        do {
            try eventStore.save(event, span: .thisEvent)
            completion(.success(true))
        } catch {
            completion(.failure(error))
        }
    }
}
