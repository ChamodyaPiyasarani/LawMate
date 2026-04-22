import SwiftUI

struct RescheduleBookingView: View {
    let appointment: FBAppointment
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date
    @State private var selectedTimeSlot: String?
    @State private var isUpdating = false
    
    let timeSlots = [
        "09:00 AM", "10:00 AM", "11:00 AM",
        "01:00 PM", "02:00 PM", "03:00 PM",
        "04:00 PM", "05:00 PM"
    ]
    
    init(appointment: FBAppointment) {
        self.appointment = appointment
        let day = Calendar.current.startOfDay(for: appointment.date)
        _selectedDate = State(initialValue: day)
        _selectedTimeSlot = State(initialValue: appointment.time)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: Custom Header
                LawMateNavigationBar(
                    title: "Reschedule",
                    showBack: true,
                    onBack: { dismiss() }
                )
                .padding(.top, 64)
                .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        Text("Select New Date")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.lmPrimary)
                            .padding(.top, 20)
                        
                        // MARK: Mock Calendar Placeholder (DatePicker)
                        DatePicker(
                            "Select Date",
                            selection: $selectedDate,
                            in: Date()...,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        
                        Text("Select Time")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.lmPrimary)
                            .padding(.top, 10)
                        
                        // MARK: Time Slots Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(timeSlots, id: \.self) { slot in
                                Button {
                                    selectedTimeSlot = slot
                                } label: {
                                    Text(slot)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(selectedTimeSlot == slot ? .white : .lmPrimary)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(selectedTimeSlot == slot ? Color.lmPrimary : Color.white)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().stroke(Color.lmPrimary.opacity(0.2), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Spacer(minLength: 40)
                        
                        // MARK: Confirm Button
                        Button {
                            guard let appointmentId = appointment.id else {
                                ToastManager.shared.show(title: "Update Failed", message: "Appointment not found.", type: .error)
                                return
                            }
                            guard let timeSlot = selectedTimeSlot else { return }
                            isUpdating = true

                            FirestoreManager.shared.validateAppointmentSlot(lawyerId: appointment.lawyerId, date: selectedDate, time: timeSlot, excludingAppointmentId: appointmentId) { canBook, reason in
                                DispatchQueue.main.async {
                                    if canBook {
                                        FirestoreManager.shared.updateAppointmentSchedule(appointmentId: appointmentId, newDate: selectedDate, newTime: timeSlot) { success, updateReason in
                                            DispatchQueue.main.async {
                                                isUpdating = false
                                                if success {
                                                    EventKitManager.shared.createEvent(
                                                        title: "Rescheduled Consultation",
                                                        startDate: selectedDate,
                                                        endDate: selectedDate.addingTimeInterval(3600)
                                                    ) { _, _ in
                                                        DispatchQueue.main.async {
                                                            dismiss()
                                                        }
                                                    }
                                                } else {
                                                    ToastManager.shared.show(title: "Booking Unavailable", message: updateReason ?? "This slot is not available.", type: .error)
                                                }
                                            }
                                        }
                                    } else {
                                        isUpdating = false
                                        ToastManager.shared.show(title: "Booking Unavailable", message: reason ?? "This slot is not available.", type: .error)
                                    }
                                }
                            }
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
                            .background(selectedTimeSlot == nil || isUpdating ? Color.gray : Color.lmPrimary)
                            .clipShape(Capsule())
                            .shadow(color: selectedTimeSlot == nil || isUpdating ? .clear : Color.lmPrimary.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(selectedTimeSlot == nil || isUpdating)
                        .buttonStyle(.plain)
                        .padding(.bottom, 120) // Moved significantly higher to avoid tab bar
                    }
                    .padding(.horizontal, 24)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
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
        status: "Confirmed"
    ))
}
