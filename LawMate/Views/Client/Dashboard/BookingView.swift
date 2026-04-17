import SwiftUI
import MapKit

struct BookingView: View {
    let lawyer: Lawyer
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedService = "Case Review (1 hour)"
    @State private var selectedDate = Date()
    @State private var selectedTime: String? = "10:30 AM"
    @State private var isVideoCall = false
    @State private var caseDescription = ""
    
    // Validation Errors
    @State private var descriptionError: String?
    
    let services = ["Case Review (1 hour)", "Legal Consultation (30 mins)", "Document Drafting", "Court Representation"]
    let timeSlots = ["09:00 AM", "10:30 AM", "01:00 PM", "02:30 PM"]
    let bookedDays = [1, 5, 8, 12, 19, 24, 28] // Example booked days for this month
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Green blob top-left
            GreenBlobBackground(style: .client)
                .frame(height: 300)

            VStack(spacing: 0) {
                // MARK: Navigation Bar
                LawMateNavigationBar(
                    title: "Lawyer Bookings",
                    showBack: true,
                    showNotification: true,
                    onBack: { dismiss() }
                )
                .padding(.top, 64)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        // MARK: Service Selection
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(title: "Service Selection")
                            
                            Menu {
                                ForEach(services, id: \.self) { service in
                                    Button(service) { selectedService = service }
                                }
                            } label: {
                                HStack {
                                    Text(selectedService)
                                        .foregroundColor(.lmTextPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.lmTextSecondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 24)

                        // MARK: Calendar Card
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(title: "Select Date")
                            
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, 24)

                        // MARK: Time Slots
                        VStack(alignment: .leading, spacing: 16) {
                            SectionTitle(title: "Available Time Slots")
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                                ForEach(timeSlots, id: \.self) { time in
                                    Button {
                                        selectedTime = time
                                    } label: {
                                        Text(time)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(selectedTime == time ? .white : .lmTextPrimary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(selectedTime == time ? Color.lmPrimary : Color.white.opacity(0.6))
                                            .clipShape(Capsule())
                                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // MARK: Service Selection (Video/InPerson)
                        VStack(alignment: .leading, spacing: 16) {
                            SectionTitle(title: "Service Selection")
                            
                            HStack(spacing: 16) {
                                ServiceTypeButton(icon: "video.fill", title: "Video call", isSelected: isVideoCall) {
                                    isVideoCall = true
                                }
                                ServiceTypeButton(icon: "building.2.fill", title: "In Person", isSelected: !isVideoCall) {
                                    isVideoCall = false
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // MARK: Description
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(title: "Brief Case Description")
                            
                            VStack(alignment: .leading, spacing: 4) {
                                TextEditor(text: $caseDescription)
                                    .frame(height: 120)
                                    .padding(12)
                                    .background(Color.white.opacity(0.4))
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(descriptionError != nil ? Color.red : Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                
                                if let error = descriptionError {
                                    Text(error)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.red)
                                        .padding(.leading, 12)
                                        .transition(.opacity)
                                }
                            }
                            .animation(.easeInOut(duration: 0.2), value: descriptionError)
                        }
                        .padding(.horizontal, 24)

                        // MARK: Confirm Button
                        LawMatePrimaryButton(title: "Confirm Appointment") {
                            if validateForm() {
                                EventKitManager.shared.createEvent(
                                    title: "Consultation with \(lawyer.name)",
                                    startDate: selectedDate,
                                    endDate: selectedDate.addingTimeInterval(3600), // 1 hour consultation
                                    location: isVideoCall ? "Video Call" : lawyer.location,
                                    notes: caseDescription
                                ) { success, error in
                                    DispatchQueue.main.async {
                                        if success {
                                            ToastManager.shared.show(title: "Booking Confirmed", message: "Your appointment is set.", type: .success)
                                            NotificationManager.shared.scheduleNotification(
                                                title: "Booking Confirmed",
                                                body: "Your appointment with \(lawyer.name) has been booked successfully."
                                            )
                                            dismiss()
                                        } else {
                                            ToastManager.shared.show(title: "Booking Failed", message: error?.localizedDescription ?? "Could not save to calendar.", type: .warning)
                                            dismiss()
                                        }
                                    }
                                }
                            } else {
                                ToastManager.shared.show(title: "Validation Error", message: "Please enter a case description.", type: .error)
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                        .padding(.bottom, 220) // Space for global TabBar
                    }
                    .padding(.top, 20)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func validateForm() -> Bool {
        var isValid = true
        
        descriptionError = caseDescription.trimmingCharacters(in: .whitespaces).isEmpty ? "Description is required" : nil
        if descriptionError != nil { isValid = false }
        
        return isValid
    }
}

// MARK: - Helper Components
struct SectionTitle: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.lmTextSecondary)
    }
}

struct ServiceTypeButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.lmPrimary : Color.white.opacity(0.6))
            .foregroundColor(isSelected ? .white : .lmTextSecondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BookingView(lawyer: Lawyer(
        id: "L1",
        name: "Nimal Perera",
        specialty: "Criminal Law",
        bio: "Criminal specialist",
        description: "Bio",
        experience: "14 YEARS",
        casesWon: "250 +",
        rating: 4.8,
        location: "Colombo",
        image: "person",
        coordinate: .init(latitude: 0, longitude: 0)
    ))
}
