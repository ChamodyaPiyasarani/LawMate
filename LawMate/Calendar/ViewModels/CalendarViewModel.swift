import Foundation
import SwiftUI
import EventKit
import Combine

class CalendarViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var currentMonth: Date = Date()
    @Published var eventsForSelectedDate: [EKEvent] = [] // System events
    @Published var appointmentsForSelectedDate: [FBAppointment] = [] // LawMate events
    @Published var monthEventsMap: [Date: [EKEvent]] = [:]
    @Published var monthAppointmentsMap: [Date: [FBAppointment]] = [:]
    @Published var isAuthorized = false
    @Published var errorMessage: String? = nil
    
    // Computed categorizations using standardized FBAppointment.category
    var upcomingAppointments: [FBAppointment] {
        appointmentsForSelectedDate.filter { $0.category == .upcoming }
    }
    
    var overdueAppointments: [FBAppointment] {
        appointmentsForSelectedDate.filter { $0.category == .overdue }
    }
    
    var completedAppointments: [FBAppointment] {
        appointmentsForSelectedDate.filter { $0.category == .done }
    }
    
    private let service = EventKitService.shared
    private let firestore = FirestoreManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Observe System Calendar Authorization
        service.$isAuthorized
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authorized in
                self?.isAuthorized = authorized
                if authorized {
                    self?.refreshMonthData()
                }
            }
            .store(in: &cancellables)
            
        // Observe Firestore Appointments (Reactive Sync)
        firestore.$appointments
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshFirestoreAppointments()
            }
            .store(in: &cancellables)
            
        // Initial Refresh
        refreshMonthData()
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
        // 1. Fetch system events if authorized
        if isAuthorized {
            monthEventsMap = service.fetchEventsForMonth(date: currentMonth)
        }
        
        // 2. Fetch LawMate appointments (Always sync via Firestore)
        refreshFirestoreAppointments()
    }
    
    private func refreshFirestoreAppointments() {
        let calendar = Calendar.current
        var map: [Date: [FBAppointment]] = [:]
        
        for appointment in firestore.appointments {
            let day = calendar.startOfDay(for: appointment.date)
            if map[day] != nil {
                map[day]?.append(appointment)
            } else {
                map[day] = [appointment]
            }
        }
        
        DispatchQueue.main.async {
            self.monthAppointmentsMap = map
            self.refreshSelectedDateEvents()
        }
    }
    
    func refreshSelectedDateEvents() {
        let calendar = Calendar.current
        
        // 1. Filter system events
        if isAuthorized {
            eventsForSelectedDate = service.fetchEvents(for: selectedDate)
        }
        
        // 2. Filter LawMate appointments
        let startOfDay = calendar.startOfDay(for: selectedDate)
        appointmentsForSelectedDate = firestore.appointments.filter {
            calendar.startOfDay(for: $0.date) == startOfDay
        }
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
    
    func addAppointment(_ appointment: FBAppointment) {
        firestore.createAppointmentWithValidation(appointment) { [weak self] success, reason, appointmentId in
            DispatchQueue.main.async {
                if success {
                    self?.refreshMonthData()
                    self?.refreshSelectedDateEvents()
                } else {
                    self?.errorMessage = reason ?? "Failed to save appointment to the database."
                }
            }
        }
    }
    
    func getColor(for date: Date) -> Color {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let appointments = monthAppointmentsMap[day] ?? []
        let activeAppointments = appointments.filter { 
            let s = $0.status.lowercased()
            return s != "cancelled" && s != "rejected"
        }
        let firestoreCount = activeAppointments.count
        
        if firestoreCount == 0 {
            return .clear
        } else if firestoreCount < 3 {
            return .yellow.opacity(0.3)
        } else {
            return Color.lmPrimary 
        }
    }
    
    func getStatusColor(for date: Date) -> Color {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let appointments = monthAppointmentsMap[day] ?? []
        let count = appointments.filter { 
            let s = $0.status.lowercased()
            return s != "cancelled" && s != "rejected"
        }.count
        
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
        let appointments = monthAppointmentsMap[day] ?? []
        let count = appointments.filter { 
            let s = $0.status.lowercased()
            return s != "cancelled" && s != "rejected"
        }.count
        
        if count >= 3 {
            return .white
        } else {
            return .lmPrimary
        }
    }
}
