import Foundation
import SwiftUI
import EventKit
import Combine

class CalendarViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var currentMonth: Date = Date()
    @Published var eventsForSelectedDate: [EKEvent] = []
    @Published var monthEventsMap: [Date: [EKEvent]] = [:]
    @Published var isAuthorized = false
    @Published var errorMessage: String? = nil
    
    private let service = EventKitService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        service.$isAuthorized
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authorized in
                self?.isAuthorized = authorized
                if authorized {
                    self?.refreshMonthData()
                    self?.refreshSelectedDateEvents()
                }
            }
            .store(in: &cancellables)
    }
    
    func requestAccess() {
        service.requestAccess { [weak self] granted in
            if granted {
                self?.refreshMonthData()
                self?.refreshSelectedDateEvents()
            } else {
                self?.errorMessage = "Calendar access is required to manage your appointments."
            }
        }
    }
    
    func refreshMonthData() {
        guard isAuthorized else { return }
        monthEventsMap = service.fetchEventsForMonth(date: currentMonth)
    }
    
    func refreshSelectedDateEvents() {
        guard isAuthorized else { return }
        eventsForSelectedDate = service.fetchEvents(for: selectedDate)
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
