import SwiftUI

struct RescheduleBookingView: View {
    let appointment: FBAppointment
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date
    @State private var isUpdating = false
    @State private var isDateValid = true
    @State private var checkingCapacity = false
    
    init(appointment: FBAppointment) {
        self.appointment = appointment
        self._selectedDate = State(initialValue: appointment.date)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: Custom Header
                LawMateNavigationBar(
                    title: "Reschedule",
                    showBack: true,
                    onBack: { dismiss() }
                )
                .padding(.top, 54)
                .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        Text("Select New Date & Time")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.lmPrimary)
                            .padding(.top, 12)
                        
                        // MARK: Unified Date & Time Picker
                        DatePicker(
                            "Select Date & Time",
                            selection: $selectedDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
                        
                        if !isDateValid {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("Lawyer is fully booked on this date (Max 3 appointments).")
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                        }
                        
                        if checkingCapacity {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Checking availability...")
                                    .font(.system(size: 12))
                                    .foregroundColor(.lmTextSecondary)
                            }
                            .padding(.horizontal, 8)
                        }
                        
                        Spacer(minLength: 20)
                        
                        // MARK: Confirm Button
                        Button {
                            saveReschedule()
                        } label: {
                            HStack {
                                Spacer()
                                if isUpdating {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Confirm Reschedule")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 16)
                            .background(!isDateValid || isUpdating || checkingCapacity ? Color.gray : Color.lmPrimary)
                            .clipShape(Capsule())
                            .shadow(color: !isDateValid || isUpdating || checkingCapacity ? .clear : Color.lmPrimary.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(!isDateValid || isUpdating || checkingCapacity)
                        .buttonStyle(.plain)
                        .padding(.bottom, 100) 
                    }
                    .padding(.horizontal, 24)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: selectedDate) { _, newValue in
            validateDate(newValue)
        }
        .onAppear {
            validateDate(selectedDate)
        }
    }
    
    private func validateDate(_ date: Date) {
        checkingCapacity = true
        FirestoreManager.shared.checkLawyerCapacity(
            lawyerId: appointment.lawyerId,
            date: date,
            excludingAppointmentId: appointment.id
        ) { available in
            checkingCapacity = false
            isDateValid = available
        }
    }
    
    private func saveReschedule() {
        guard let appointmentId = appointment.id else {
            ToastManager.shared.show(title: "Update Failed", message: "Appointment not found.", type: .error)
            return
        }
        
        isUpdating = true
        let timeString = formatTime(selectedDate)
        
        FirestoreManager.shared.rescheduleAppointment(
            appointmentId: appointmentId,
            newDate: selectedDate,
            newTime: timeString
        ) { success in
            if success {
                // Sync to Local Calendar
                EventKitManager.shared.createEvent(
                    title: "Rescheduled Consultation",
                    startDate: selectedDate,
                    endDate: selectedDate.addingTimeInterval(3600)
                ) { _, _ in }
                
                // Notify Lawyer
                let senderName = AuthService.shared.currentUser?.fullName ?? "Client"
                let notification = FBNotification(
                    title: "Appointment Rescheduled",
                    body: "\(senderName) has suggested a new time: \(timeString) on \(formatDate(selectedDate))",
                    type: "appointment",
                    timestamp: Date(),
                    relatedId: appointmentId
                )
                FirestoreManager.shared.addNotification(notification, toUserId: appointment.lawyerId)
                
                DispatchQueue.main.async {
                    isUpdating = false
                    dismiss()
                }
            } else {
                DispatchQueue.main.async {
                    isUpdating = false
                    ToastManager.shared.show(title: "Error", message: "Failed to reschedule. Please try again.", type: .error)
                }
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "hh:mm a"
        return f.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy"
        return f.string(from: date)
    }
}

#Preview {
    RescheduleBookingView(appointment: FBAppointment(
        clientId: "C1",
        clientName: "Client",
        lawyerId: "L1",
        lawyerName: "Lawyer",
        service: "Consultation",
        date: Date(),
        time: "09:00 AM",
        method: "Video Call",
        description: "",
        status: "Pending"
    ))
}
