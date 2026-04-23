import SwiftUI
import MapKit
import PhotosUI

struct AddCaseView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: Form State
    @State private var caseTitle: String = ""
    @State private var caseType: String = "Family Law"
    @State private var clientName: String = ""
    @State private var description: String = ""
    @State private var status: String = "Pending"
    @State private var priority: String = "Medium"
    @State private var hearingDate: Date = Date()
    @State private var isHearingDateSet: Bool = false
    @State private var location: CLLocationCoordinate2D? = nil
    @State private var selectedAddress: String = ""
    @State private var showMapPicker = false
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    // MARK: Attachments State
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isFileImporterPresented = false
    
    // MARK: Search State
    @State private var showClientSuggestions = false
    @State private var selectedClientId: String = ""
    @State private var selectedClientImage: String? = nil
    @ObservedObject private var firestore = FirestoreManager.shared
    
    var filteredClients: [User] {
        firestore.clients.filter { $0.fullName.lowercased().contains(clientName.lowercased()) }
    }
    
    let caseTypes = ["Family Law", "Criminal Law", "Civil Law", "Corporate Law", "Divorce", "Property Law"]
    let statuses = ["Active", "Closed", "Pending"]
    let priorities = ["Low", "Medium", "High"]

    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Flipped Green blob (Lawyer Style)
            GreenBlobBackground(style: .lawyer)
                .frame(height: 350)
                .offset(y: -50)
            
            VStack(spacing: 0) {
                // MARK: Custom Header
                LawMateNavigationBar(
                    title: "Add New Case",
                    showBack: true,
                    showNotification: false,
                    onBack: { dismiss() }
                )
                .padding(.top, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // MARK: General Information Section
                        formSection(title: "General Information") {
                            VStack(spacing: 16) {
                                LawMateTextField(icon: "pencil", placeholder: "Case Title", text: $caseTitle)
                                
                                // Case Type Picker
                                pickerField(title: "Case Type", icon: "tag.fill") {
                                    Picker("", selection: $caseType) {
                                        ForEach(caseTypes, id: \.self) { type in
                                            Text(type).tag(type)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                            }
                        }
                        
                        // MARK: Client Information Section
                        formSection(title: "Client Information") {
                            VStack(alignment: .leading, spacing: 8) {
                                LawMateTextField(icon: "person.badge.shield.fill", placeholder: "Search Client Name", text: $clientName)
                                    .onChange(of: clientName) { _, newValue in
                                        // Hide suggestions if exact match found
                                        let exactMatch = firestore.clients.contains(where: { $0.fullName.lowercased() == newValue.lowercased() })
                                        showClientSuggestions = !newValue.isEmpty && !exactMatch
                                    }
                                
                                if showClientSuggestions && !filteredClients.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(filteredClients) { client in
                                            Button {
                                                clientName = client.fullName
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
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                                }
                            }
                        }
                        
                        // MARK: Case Details Section
                        formSection(title: "Details & Description") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Case Description")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.lmTextSecondary)
                                
                                TextEditor(text: $description)
                                    .frame(height: 120)
                                    .padding(12)
                                    .background(Color.white.opacity(0.1))
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                        
                        // MARK: Status & Priority Section
                        formSection(title: "Status & Priority") {
                            VStack(spacing: 20) {
                                segmentedSection(title: "Case Status", selection: $status, options: statuses)
                                segmentedSection(title: "Priority Level", selection: $priority, options: priorities)
                            }
                        }
                        
                        // MARK: Scheduling (Optional Date)
                        formSection(title: "Hearing Date") {
                            VStack(spacing: 16) {
                                HStack {
                                    Toggle(isOn: $isHearingDateSet) {
                                        Text(isHearingDateSet ? "Date Scheduled" : "Not Scheduled Yet")
                                            .font(.lmBody)
                                            .foregroundColor(isHearingDateSet ? .lmPrimary : .lmTextSecondary)
                                    }
                                    .tint(.lmPrimary)
                                }
                                
                                if isHearingDateSet {
                                    DatePicker("Select Date", selection: $hearingDate, displayedComponents: .date)
                                        .datePickerStyle(.graphical)
                                        .accentColor(.lmPrimary)
                                        .padding()
                                        .background(Color.white.opacity(0.1))
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                }
                            }
                        }
                        
                        // MARK: Attachments & Location
                        formSection(title: "Additional Info") {
                            VStack(spacing: 20) {
                                // Attachments
                                HStack(spacing: 12) {
                                    PhotosPicker(selection: $selectedItems, matching: .images) {
                                        attachmentButton(title: "Attach Photos", icon: "photo.on.rectangle.angled")
                                    }
                                    
                                    Button {
                                        isFileImporterPresented = true
                                    } label: {
                                        attachmentButton(title: "Attach Files", icon: "doc.badge.plus")
                                    }
                                }
                                
                                // Location
                                Button {
                                    showMapPicker = true
                                } label: {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "mappin.and.ellipse")
                                            Text(selectedAddress.isEmpty ? "Set Location (Optional)" : selectedAddress)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                        }
                                        .font(.lmBody)
                                        .foregroundColor(.lmPrimary)
                                        .padding()
                                        .background(Color.white.opacity(0.1))
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        
                                        if let coord = location {
                                            Map(position: .constant(.region(MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))))) {
                                                Marker("Case Location", coordinate: coord)
                                            }
                                            .frame(height: 150)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .disabled(true) // Static preview
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // MARK: Save Button
                        LawMatePrimaryButton(title: "Save Case") {
                            let currUser = AuthService.shared.currentUser
                            let lawyerName = currUser?.fullName ?? "Atty. Placeholder"
                            let lawyerId = currUser?.id ?? ""
                            let lawyerImage = currUser?.profileImage
                            
                            let newCase = FBLegalCase(
                                caseNumber: "LAW-\(Int.random(in: 1000...9999))",
                                title: caseTitle.isEmpty ? "Untitled Case" : caseTitle,
                                clientName: clientName.isEmpty ? "Unknown Client" : clientName,
                                clientId: selectedClientId,
                                clientImage: selectedClientImage,
                                lawyerName: lawyerName,
                                lawyerId: lawyerId,
                                lawyerImage: lawyerImage,
                                type: caseType,
                                status: status,
                                priority: priority,
                                createdDate: Date(),
                                stages: [FBCaseStage(title: "Draft Phase", description: "Case initialized in system.", isCompleted: false)]
                            )
                            
                            FirestoreManager.shared.addCase(newCase)
                            NotificationManager.shared.scheduleNotification(
                                title: "Case Added", 
                                body: "Successfully created active case: \(newCase.title)"
                            )
                            dismiss()
                        }
                        .padding(.top, 20)
                        
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
        }
        .fileImporter(isPresented: $isFileImporterPresented, allowedContentTypes: [.pdf, .text], allowsMultipleSelection: true) { result in
            // Handle files
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showMapPicker) {
            LocationPickerView { coord in
                self.location = coord
                reverseGeocode(coord)
            }
        }
        .onAppear {
            firestore.listenForClients()
        }
    }
    
    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                let road = placemark.thoroughfare ?? ""
                let district = placemark.subAdministrativeArea ?? ""
                let locality = placemark.locality ?? ""
                let country = placemark.country ?? ""
                
                DispatchQueue.main.async {
                    var components: [String] = []
                    if !road.isEmpty { components.append(road) }
                    if !locality.isEmpty { components.append(locality) }
                    if !district.isEmpty { components.append(district) }
                    if !country.isEmpty { components.append(country) }
                    
                    if !components.isEmpty {
                        self.selectedAddress = components.joined(separator: ", ")
                    } else {
                        self.selectedAddress = "Unknown Location"
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func formSection<Content: View>(title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.lmPrimary)
                .padding(.leading, 4)
            
            content()
        }
    }
    
    private func pickerField<Content: View>(title: String, icon: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.lmTextSecondary)
                .frame(width: 20)
            Text(title)
                .font(.lmField)
                .foregroundColor(.lmTextPrimary)
            Spacer()
            content()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
    
    private func segmentedSection(title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.lmTextSecondary)
            
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { opt in
                    Text(opt).tag(opt)
                }
            }
            .pickerStyle(.segmented)
            .accentColor(.lmPrimary)
        }
    }
    
    private func attachmentButton(title: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
            Text(title)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(.lmPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.1))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

#Preview {
    AddCaseView()
}
