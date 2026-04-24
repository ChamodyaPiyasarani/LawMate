import SwiftUI
import EventKit

struct EventListView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @State private var showingAddEvent = false
    @State private var selectedService = "Case Review (1 hour)"
    @State private var selectedTime: String? = nil
    @State private var isVideoCall = false
    @State private var caseDescription = ""
    @State private var isSaving = false
    @State private var selectedScheduleTab = 0 // 0: Upcoming, 1: Completed
    
    // Search State
    @State private var clientSearchName = ""
    @State private var showClientSuggestions = false
    @State private var selectedClientId = ""
    @State private var selectedClientImage: String? = nil
    
    var filteredClients: [User] {
        FirestoreManager.shared.clients.filter { 
            clientSearchName.isEmpty || $0.fullName.lowercased().contains(clientSearchName.lowercased()) 
        }
    }
    
    let services = ["Case Review (1 hour)", "Legal Consultation (30 mins)", "Document Drafting", "Court Representation"]
    let timeSlots = ["09:00 AM", "10:30 AM", "01:00 PM", "02:30 PM"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Schedule for \(viewModel.selectedDate, formatter: dateFormatter)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    let totalCount = viewModel.appointmentsForSelectedDate.count
                    Text("\(totalCount) Appointments scheduled")
                        .font(.system(size: 13))
                        .foregroundColor(.lmTextSecondary)
                }
                
                Spacer()
                
                if (viewModel.eventsForSelectedDate.count + viewModel.appointmentsForSelectedDate.count) < 5 {
                    Button {
                        showingAddEvent = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.lmPrimary)
                    }
                }
            }
            .padding(.horizontal, 24)
            
            .padding(.horizontal, 24)
            
            // MARK: Schedule Tabs
            HStack(spacing: 0) {
                TabButton(title: "Upcoming", isSelected: selectedScheduleTab == 0) {
                    selectedScheduleTab = 0
                }
                TabButton(title: "Completed", isSelected: selectedScheduleTab == 1) {
                    selectedScheduleTab = 1
                }
            }
            .padding(4)
            .background(Color.black.opacity(0.05))
            .clipShape(Capsule())
            .padding(.horizontal, 24)
            
            let displayList = (selectedScheduleTab == 0) ? viewModel.upcomingAppointments : viewModel.completedAppointments
            
            if displayList.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: selectedScheduleTab == 0 ? "calendar.badge.plus" : "clock.arrow.circlepath")
                        .font(.system(size: 40))
                        .foregroundColor(.lmPrimary.opacity(0.2))
                    Text(selectedScheduleTab == 0 ? "No upcoming appointments." : "No completed appointments yet.")
                        .font(.system(size: 14))
                        .foregroundColor(.lmTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(displayList) { appointment in
                        AppointmentRowView(appointment: appointment)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .sheet(isPresented: $showingAddEvent) {
            addEventSheet
        }
        .onAppear {
            FirestoreManager.shared.listenForClients()
        }
    }
    
    private var addEventSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: Client Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Client")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.lmPrimary)
                        
                        LawMateTextField(icon: "person.badge.shield.fill", placeholder: "Search Client Name", text: $clientSearchName)
                            .onChange(of: clientSearchName) { _, newValue in
                                let exactMatch = FirestoreManager.shared.clients.contains(where: { $0.fullName.lowercased() == newValue.lowercased() })
                                showClientSuggestions = !newValue.isEmpty && !exactMatch
                            }
                        
                        if showClientSuggestions && !filteredClients.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(filteredClients) { client in
                                    Button {
                                        clientSearchName = client.fullName
                                        selectedClientId = client.id
                                        selectedClientImage = client.profileImage
                                        showClientSuggestions = false
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(client.fullName)
                                                .font(.lmBody)
                                                .foregroundColor(.lmPrimary)
                                            Text(client.email)
                                                .font(.system(size: 11))
                                                .foregroundColor(.lmTextSecondary)
                                        }
                                    }
                                    if client.id != filteredClients.last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                        }
                    }
                    
                    // MARK: Service Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Service Type")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.lmPrimary)
                        
                        Menu {
                            ForEach(services, id: \.self) { service in
                                Button(service) {
                                    selectedService = service
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedService)
                                    .font(.system(size: 14, weight: .medium))
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.lmPrimary)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lmPrimary.opacity(0.1), lineWidth: 1))
                        }
                    }
                    
                    // MARK: Time Slot
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Available Time Slots")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.lmPrimary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(timeSlots, id: \.self) { time in
                                Button {
                                    selectedTime = time
                                } label: {
                                    Text(time)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(selectedTime == time ? .white : .lmPrimary)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(selectedTime == time ? Color.lmPrimary : Color.white)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(Color.lmPrimary.opacity(0.2), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // MARK: Method
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Meeting Method")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.lmPrimary)
                        
                        HStack(spacing: 16) {
                            Button { isVideoCall = true } label: {
                                Label("Video", systemImage: "video")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(isVideoCall ? Color.lmPrimary : Color.white)
                                    .foregroundColor(isVideoCall ? .white : .lmPrimary)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color.lmPrimary.opacity(0.2), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            
                            Button { isVideoCall = false } label: {
                                Label("In-Person", systemImage: "building.2")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(!isVideoCall ? Color.lmPrimary : Color.white)
                                    .foregroundColor(!isVideoCall ? .white : .lmPrimary)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color.lmPrimary.opacity(0.2), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // MARK: Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.lmPrimary)
                        
                        TextEditor(text: $caseDescription)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lmPrimary.opacity(0.1), lineWidth: 1))
                    }
                }
                .padding(24)
            }
            .navigationTitle("New Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddEvent = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if !isSaving {
                            validateAndSave()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(.lmPrimary)
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(selectedClientId.isEmpty || isSaving)
                }
            }
        }
    }
    
    private func validateAndSave() {
        guard let lawyer = AuthService.shared.currentUser else { return }
        
        if selectedClientId.isEmpty {
            ToastManager.shared.show(title: "No Client", message: "Please search and select a client.", type: .error)
            return
        }
        
        guard let time = selectedTime, !time.isEmpty else {
            ToastManager.shared.show(title: "Select Time", message: "Please select a time slot.", type: .error)
            return
        }
        
        isSaving = true
        
        // Use Firestore as source of truth — validates limit AND time conflict
        FirestoreManager.shared.validateAppointmentSlot(lawyerId: lawyer.id, date: viewModel.selectedDate, time: time) { canBook, reason in
            DispatchQueue.main.async {
                if canBook {
                    self.saveManualAppointment()
                } else {
                    self.isSaving = false
                    ToastManager.shared.show(title: "Booking Unavailable", message: reason ?? "This slot is not available.", type: .error)
                }
            }
        }
    }
    
    private func saveManualAppointment() {
        guard !selectedClientId.isEmpty,
              let currentLawyer = AuthService.shared.currentUser else { 
            isSaving = false
            return 
        }

        let appointmentDate = combineDateAndTime(day: viewModel.selectedDate, timeString: selectedTime ?? "")
        
        let appointment = FBAppointment(
            clientId: selectedClientId,
            clientName: clientSearchName,
            lawyerId: currentLawyer.id,
            lawyerName: currentLawyer.fullName,
            lawyerImage: currentLawyer.profileImage,
            lawyerSpecialty: currentLawyer.specialty,
            service: selectedService,
            date: appointmentDate,
            time: selectedTime ?? "TBD",
            method: isVideoCall ? "Video Call" : "In Person",
            description: caseDescription,
            status: "Confirmed"
        )

        FirestoreManager.shared.createAppointmentWithValidation(appointment) { success, reason in
            DispatchQueue.main.async {
                if success {
                    // Notify Client
                    let notification = FBNotification(
                        title: "New Appointment Booked",
                        body: "Lawyer \(currentLawyer.fullName) has scheduled a \(selectedService) for you.",
                        type: "appointment",
                        timestamp: Date(),
                        relatedId: appointment.id
                    )
                    FirestoreManager.shared.addNotification(notification, toUserId: selectedClientId)

                    isSaving = false
                    showingAddEvent = false
                    resetForm()
                } else {
                    isSaving = false
                    ToastManager.shared.show(title: "Booking Unavailable", message: reason ?? "This slot is not available.", type: .error)
                }
            }
        }
    }
    
    private func resetForm() {
        clientSearchName = ""
        selectedClientId = ""
        selectedClientImage = nil
        selectedService = "Case Review (1 hour)"
        selectedTime = "09:00 AM"
        isVideoCall = false
        caseDescription = ""
    }
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy"
        return f
    }

    private func combineDateAndTime(day: Date, timeString: String) -> Date {
        return FirestoreManager.shared.combineDateAndTime(day: day, timeString: timeString) ?? day
    }
}

struct EventRow: View {
    let event: EKEvent
    
    var body: some View {
        HStack(spacing: 16) {
            VStack {
                Text(event.startDate, formatter: timeFormatter)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.lmPrimary)
                Rectangle()
                    .fill(Color.lmPrimary.opacity(0.2))
                    .frame(width: 2, height: 20)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.lmPrimary)
                
                if let notes = event.notes {
                    Text(notes)
                        .font(.system(size: 12))
                        .foregroundColor(.lmTextSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: typeIcon)
                .foregroundColor(typeColor)
                .font(.system(size: 18))
        }
        .padding(16)
        .background(Color.white.opacity(0.6))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.5), lineWidth: 1))
    }
    
    private var typeIcon: String {
        if event.title.contains("Hearing") { return "gavel.fill" }
        if event.title.contains("Consultation") { return "person.2.fill" }
        return "calendar"
    }
    
    private var typeColor: Color {
        if event.title.contains("Hearing") { return .red }
        if event.title.contains("Consultation") { return .blue }
        return .lmPrimary
    }
    
    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }
}

