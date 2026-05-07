import SwiftUI
import MapKit

struct BookingView: View {
    let lawyer: Lawyer?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firestore: FirestoreManager
    
    @State private var selectedService = "Case Review (1 hour)"
    @State private var selectedDate = Date()
    @State private var isVideoCall = false
    @State private var caseDescription = ""
    @State private var checkingCapacity = false
    @State private var validationMessage: String?
    
    // Lawyer Selection State
    @State private var selectedLawyer: Lawyer?
    @State private var lawyerSearchText = ""
    @State private var showSuggestions = false
    
    // Validation & Loading State
    @State private var descriptionError: String?
    @State private var isBooking = false
    
    let services = ["Case Review (1 hour)", "Legal Consultation (30 mins)", "Document Drafting", "Court Representation"]
    
    var allLawyers: [Lawyer] {
        firestore.lawyers.map { user in
            let expValue = Int(user.experience?.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }.first ?? "0") ?? 0
            let wonValue = Int(user.casesWon?.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }.first ?? "0") ?? 0
            
            let lat = user.latitude ?? 6.9271
            let lng = user.longitude ?? 79.8612
            
            return Lawyer(
                id: user.id,
                name: user.fullName,
                specialty: user.specialty ?? "General Practice",
                bio: user.bio ?? "Professional Lawyer",
                description: user.bio ?? "",
                experience: user.experience ?? "5 YEARS",
                experienceYears: expValue,
                casesWon: user.casesWon ?? "0",
                wonCount: wonValue,
                rating: user.rating ?? 0.0,
                reviewCount: user.reviewCount ?? 0,
                location: user.address ?? "Colombo, Sri Lanka",
                image: user.profileImage ?? "",
                coordinate: .init(latitude: lat, longitude: lng)
            )
        }
    }
    
    var lawyerSuggestions: [Lawyer] {
        if lawyerSearchText.isEmpty { return [] }
        return allLawyers.filter { $0.name.localizedCaseInsensitiveContains(lawyerSearchText) }
    }
    
    init(lawyer: Lawyer? = nil) {
        self.lawyer = lawyer
        _selectedLawyer = State(initialValue: lawyer)
        if let lawyer = lawyer {
            _lawyerSearchText = State(initialValue: lawyer.name)
        }
    }
                             
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
                .padding(.top, 65)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        // MARK: Lawyer Selection
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(title: selectedLawyer == nil ? "Select Lawyer" : "Selected Lawyer")
                            
                            VStack(spacing: 0) {
                                if let selected = selectedLawyer, lawyer != nil {
                                    // Pre-selected Lawyer Card (Read-only)
                                    HStack(spacing: 12) {
                                        LawMateAvatar(url: selected.image, name: selected.name, size: 48)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(selected.name)
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.lmPrimary)
                                            Text(selected.specialty)
                                                .font(.system(size: 12))
                                                .foregroundColor(.lmTextSecondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(16)
                                    .background(Color.white.opacity(0.4))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                } else {
                                    // Searchable Lawyer Selection
                                    HStack {
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.lmPrimary.opacity(0.5))
                                        
                                        TextField("Type lawyer's name...", text: $lawyerSearchText)
                                            .foregroundColor(.lmTextPrimary)
                                            .onChange(of: lawyerSearchText) { _, newValue in
                                                if selectedLawyer?.name != newValue {
                                                    selectedLawyer = nil
                                                    showSuggestions = !newValue.isEmpty && !lawyerSuggestions.isEmpty
                                                }
                                            }
                                        
                                        if selectedLawyer != nil {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                    
                                    if showSuggestions {
                                        VStack(alignment: .leading, spacing: 0) {
                                            ForEach(lawyerSuggestions) { suggestedLawyer in
                                                Button {
                                                    selectedLawyer = suggestedLawyer
                                                    lawyerSearchText = suggestedLawyer.name
                                                    showSuggestions = false
                                                } label: {
                                                    HStack(spacing: 12) {
                                                        LawMateAvatar(url: suggestedLawyer.image, name: suggestedLawyer.name, size: 32)
                                                        
                                                        VStack(alignment: .leading, spacing: 2) {
                                                            Text(suggestedLawyer.name)
                                                                .font(.system(size: 14, weight: .bold))
                                                                .foregroundColor(.lmPrimary)
                                                            Text(suggestedLawyer.specialty)
                                                                    .font(.system(size: 10))
                                                                    .foregroundColor(.lmTextSecondary)
                                                        }
                                                        Spacer()
                                                    }
                                                    .padding(.vertical, 10)
                                                    .padding(.horizontal, 16)
                                                }
                                                .buttonStyle(.plain)
                                                
                                                if suggestedLawyer.id != lawyerSuggestions.last?.id {
                                                    Divider().padding(.horizontal, 16)
                                                }
                                            }
                                        }
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
                                        .padding(.top, 4)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .zIndex(100)
                        
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

                        // MARK: Liquid Glass Date & Time Selection
                        VStack(alignment: .leading, spacing: 16) {
                            SectionTitle(title: "Schedule Consultation")
                            
                            VStack(spacing: 20) {
                                // Native Graphical Date Picker
                                DatePicker("", selection: $selectedDate, in: Calendar.current.startOfDay(for: Date())..., displayedComponents: [.date])
                                    .datePickerStyle(.graphical)
                                    .accentColor(.lmPrimary)
                                
                                Divider().background(Color.white.opacity(0.1))
                                
                                // Native Time Picker
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Select Time")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.lmPrimary)
                                        Text("Pick your preferred slot")
                                            .font(.system(size: 11))
                                            .foregroundColor(.lmTextSecondary)
                                    }
                                    Spacer()
                                    DatePicker("", selection: $selectedDate, displayedComponents: [.hourAndMinute])
                                        .labelsHidden()
                                }
                            }
                            .padding(20)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            
                            if let msg = validationMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.bubble.fill")
                                    Text(msg)
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                                .padding(.horizontal, 12)
                            }
                        }
                        .padding(.horizontal, 24)

                        // MARK: Meeting Method
                        VStack(alignment: .leading, spacing: 16) {
                            SectionTitle(title: "Meeting Method")
                            
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
                        Button {
                            if validateForm() {
                                performBooking()
                            }
                        } label: {
                            Group {
                                if isBooking {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Confirm Appointment")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(isBooking || checkingCapacity || selectedLawyer == nil || validationMessage != nil ? Color.gray : Color.lmPrimary)
                            .clipShape(Capsule())
                            .shadow(color: isBooking || checkingCapacity || selectedLawyer == nil || validationMessage != nil ? .clear : Color.lmPrimary.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isBooking || checkingCapacity || selectedLawyer == nil || validationMessage != nil)
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 60)
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .onChange(of: selectedDate) { _, _ in
            validateSlot()
        }
        .onChange(of: selectedLawyer) { _, _ in
            validateSlot()
        }
    }
    
    // MARK: - Logical Helpers
    private func validateSlot() {
        guard let lawyerId = selectedLawyer?.id else { return }
        checkingCapacity = true
        firestore.validateAppointmentSlot(
            lawyerId: lawyerId,
            date: selectedDate,
            time: formatTime(selectedDate)
        ) { success, reason in
            checkingCapacity = false
            validationMessage = success ? nil : reason
        }
    }
    
    private func performBooking() {
        isBooking = true
        guard let currentLawyer = selectedLawyer else { return }
        let client = AuthService.shared.currentUser
        
        // Final validation check
        firestore.validateAppointmentSlot(
            lawyerId: currentLawyer.id,
            date: selectedDate,
            time: formatTime(selectedDate)
        ) { success, reason in
            if !success {
                isBooking = false
                ToastManager.shared.show(title: "Slot Unavailable", message: reason ?? "Please pick another time.", type: .error)
                return
            }
            
            let appointment = FBAppointment(
                clientId: client?.id ?? "",
                clientName: client?.fullName ?? "Unknown Client",
                clientImage: client?.profileImage,
                lawyerId: currentLawyer.id,
                lawyerName: currentLawyer.name,
                lawyerImage: currentLawyer.image,
                lawyerSpecialty: currentLawyer.specialty,
                service: selectedService,
                date: selectedDate,
                time: formatTime(selectedDate),
                method: isVideoCall ? "Video Call" : "In Person",
                description: caseDescription,
                status: "Pending",
                lastActionBy: client?.id,
                locationLat: currentLawyer.coordinate.latitude,
                locationLng: currentLawyer.coordinate.longitude
            )
            
            firestore.createAppointmentWithValidation(appointment) { success, reason, appointmentId in
                guard success, let generatedId = appointmentId else {
                    DispatchQueue.main.async {
                        isBooking = false
                        ToastManager.shared.show(title: "Booking Failed", message: reason ?? "We couldn't save your appointment.", type: .error)
                    }
                    return
                }
                
                let lawyerNotification = FBNotification(
                    title: "New Booking Request",
                    body: "A new consultation has been scheduled by \(client?.fullName ?? "a client").",
                    type: "appointment",
                    timestamp: Date(),
                    relatedId: generatedId
                )
                firestore.addNotification(lawyerNotification, toUserId: currentLawyer.id)
                
                EventKitManager.shared.createEvent(
                    title: "Consultation with \(currentLawyer.name)",
                    startDate: selectedDate,
                    endDate: selectedDate.addingTimeInterval(3600),
                    location: isVideoCall ? "Video Call" : currentLawyer.location,
                    notes: caseDescription
                ) { calSuccess, _ in
                    DispatchQueue.main.async {
                        isBooking = false
                        ToastManager.shared.show(title: "Booking Confirmed", message: "Your appointment is set.", type: .success)
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func validateForm() -> Bool {
        var isValid = true
        descriptionError = caseDescription.trimmingCharacters(in: .whitespaces).isEmpty ? "Description is required" : nil
        if descriptionError != nil { isValid = false }
        if validationMessage != nil { isValid = false }
        return isValid
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: date)
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
    BookingView(lawyer: nil)
        .environmentObject(FirestoreManager.shared)
        .environmentObject(AuthService.shared)
}
