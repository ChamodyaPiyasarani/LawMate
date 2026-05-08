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
    @State private var selectedFiles: [URL] = []
    @State private var isFileImporterPresented = false
    @State private var isUpdating = false
    
    // MARK: Search State
    @State private var showClientSuggestions = false
    @State private var selectedClientId: String = ""
    @State private var selectedClientImage: String? = nil
    @EnvironmentObject var firestore: FirestoreManager
    @EnvironmentObject var auth: AuthService
    
    var filteredClients: [User] {
        firestore.clients.filter { $0.fullName.lowercased().contains(clientName.lowercased()) }
    }
    
    let caseTypes = ["Family Law", "Criminal Law", "Civil Law", "Corporate Law", "Divorce", "Property Law"]
    let statuses = ["Active", "Closed", "Pending"]
    let priorities = ["Low", "Medium", "High"]
    
    // MARK: - Initializer for Edit Mode
    var editingCase: FBLegalCase? = nil
    
    init(editingCase: FBLegalCase? = nil) {
        self.editingCase = editingCase
        if let ec = editingCase {
            _caseTitle = State(initialValue: ec.title)
            _caseType = State(initialValue: ec.type)
            _clientName = State(initialValue: ec.clientName)
            _selectedClientId = State(initialValue: ec.clientId)
            _selectedClientImage = State(initialValue: ec.clientImage)
            _description = State(initialValue: ec.description ?? "")
            _status = State(initialValue: ec.status)
            _priority = State(initialValue: ec.priority)
            _hearingDate = State(initialValue: ec.hearingDate ?? Date())
            _isHearingDateSet = State(initialValue: ec.hearingDate != nil)
            _selectedAddress = State(initialValue: ec.address ?? "")
            if let lat = ec.locationLat, let lng = ec.locationLng {
                _location = State(initialValue: CLLocationCoordinate2D(latitude: lat, longitude: lng))
            }
        }
    }

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
                    title: editingCase == nil ? "Add New Case" : "Edit Case",
                    showBack: true,
                    showNotification: false,
                    onBack: { dismiss() }
                )
                .padding(.top, 65)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // MARK: General Information Section
                        formSection(title: "General Information") {
                            VStack(spacing: 16) {
                                LawMateTextField(icon: "pencil", placeholder: "Case Title", text: $caseTitle)
                                
                                // Case Type Picker
                                pickerField(title: "Case Type", icon: "tag.fill") {
                                    Menu {
                                        Picker("", selection: $caseType) {
                                            ForEach(caseTypes, id: \.self) { type in
                                                Text(type).tag(type)
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(caseType)
                                                .font(.system(size: 14, weight: .bold))
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.system(size: 10))
                                        }
                                        .foregroundColor(.lmPrimary)
                                        .fixedSize(horizontal: true, vertical: false)
                                    }
                                }
                            }
                        }
                        
                        // MARK: Client Information Section
                        formSection(title: "Client Information") {
                            VStack(alignment: .leading, spacing: 8) {
                                LawMateTextField(icon: "person.fill", placeholder: "Search Client Name", text: $clientName)
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
                                
                                if !clientName.isEmpty && selectedClientId.isEmpty {
                                    Text("Please select a client from the suggestions")
                                        .font(.system(size: 11))
                                        .foregroundColor(.red.opacity(0.8))
                                        .padding(.leading, 4)
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
                                        attachmentButton(title: selectedImages.isEmpty ? "Attach Photos" : "\(selectedImages.count) Photos Attached", icon: selectedImages.isEmpty ? "photo.on.rectangle.angled" : "photo.fill.on.rectangle.fill")
                                    }
                                    
                                    Button {
                                        isFileImporterPresented = true
                                    } label: {
                                        attachmentButton(title: selectedFiles.isEmpty ? "Attach Files" : "\(selectedFiles.count) Files Attached", icon: selectedFiles.isEmpty ? "doc.badge.plus" : "doc.on.doc.fill")
                                    }
                                }
                                
                                // Attachment Previews
                                if !selectedImages.isEmpty || !selectedFiles.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(selectedImages, id: \.self) { img in
                                                Image(uiImage: img)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 60, height: 60)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .overlay(
                                                        Button {
                                                            if let idx = selectedImages.firstIndex(of: img) {
                                                                selectedImages.remove(at: idx)
                                                                if idx < selectedItems.count { selectedItems.remove(at: idx) }
                                                            }
                                                        } label: {
                                                            Image(systemName: "xmark.circle.fill")
                                                                .foregroundColor(.red)
                                                                .background(Color.white.clipShape(Circle()))
                                                        }
                                                        .offset(x: 25, y: -25)
                                                    )
                                            }
                                            
                                            ForEach(selectedFiles, id: \.self) { url in
                                                VStack(spacing: 4) {
                                                    Image(systemName: "doc.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(.lmPrimary)
                                                    Text(url.lastPathComponent)
                                                        .font(.system(size: 8, weight: .bold))
                                                        .lineLimit(1)
                                                        .frame(width: 60)
                                                }
                                                .frame(width: 60, height: 60)
                                                .background(Color.lmPrimary.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .overlay(
                                                    Button {
                                                        if let idx = selectedFiles.firstIndex(of: url) {
                                                            selectedFiles.remove(at: idx)
                                                        }
                                                    } label: {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundColor(.red)
                                                            .background(Color.white.clipShape(Circle()))
                                                    }
                                                    .offset(x: 25, y: -25)
                                                )
                                            }
                                        }
                                        .padding(.vertical, 8)
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
                                        }
                                    }
                                }
                            }
                        }
                        
                        // MARK: Save Button
                        LawMatePrimaryButton(title: editingCase == nil ? "Save Case" : "Update Case") {
                            let currUser = auth.currentUser
                            let lawyerName = currUser?.fullName ?? "Atty. Placeholder"
                            let lawyerId = currUser?.id ?? ""
                            let lawyerImage = currUser?.profileImage
                            
                            let targetId = editingCase?.id ?? UUID().uuidString
                            
                            var combinedDates = editingCase?.hearingDates ?? []
                            var combinedHearings = editingCase?.hearings ?? []
                            
                            if isHearingDateSet {
                                // Deduplicate: only one hearing per day in this view's logic
                                combinedDates.removeAll(where: { Calendar.current.isDate($0, inSameDayAs: hearingDate) })
                                combinedDates.append(hearingDate)
                                combinedDates.sort()
                                
                                combinedHearings.removeAll(where: { Calendar.current.isDate($0.date, inSameDayAs: hearingDate) })
                                combinedHearings.append(FBHearingDate(date: hearingDate, location: selectedAddress, notes: description))
                                combinedHearings.sort { $0.date < $1.date }
                            }
                            
                            isUpdating = true
                            
                            let modifiedCase = FBLegalCase(
                                id: targetId,
                                caseNumber: editingCase?.caseNumber ?? "LAW-\(Int.random(in: 1000...9999))",
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
                                description: description,
                                hearingDate: isHearingDateSet ? hearingDate : nil,
                                hearingDates: combinedDates,
                                hearings: combinedHearings,
                                locationLat: location?.latitude,
                                locationLng: location?.longitude,
                                address: selectedAddress,
                                createdDate: editingCase?.createdDate ?? Date(),
                                stages: editingCase?.stages ?? FBCaseStage.defaultStages
                            )
                            
                            if editingCase == nil {
                                FirestoreManager.shared.addCase(modifiedCase)
                            } else {
                                FirestoreManager.shared.updateCase(modifiedCase)
                            }
                            
                            // Sync hearing date to calendar
                            if isHearingDateSet {
                                EventKitManager.shared.createEvent(
                                    title: "Hearing: \(modifiedCase.title)",
                                    startDate: hearingDate,
                                    endDate: hearingDate.addingTimeInterval(3600),
                                    location: selectedAddress,
                                    notes: description
                                ) { _, _ in }
                            }
                            
                            // Upload Attached Photos (Base64) - Only for new ones selected in picker
                            for image in selectedImages {
                                if let data = image.jpegData(compressionQuality: 0.7) {
                                    if data.count <= 1_000_000 {
                                        let base64 = data.base64EncodedString()
                                        FirestoreManager.shared.addDocument(
                                            toCaseId: targetId,
                                            fileName: "Photo_\(UUID().uuidString.prefix(4)).jpg",
                                            fileType: "JPG",
                                            fileURL: nil,
                                            fileBase64: base64
                                        )
                                    }
                                }
                            }
                            
                            // Upload Attached Files (Base64)
                            for url in selectedFiles {
                                if let data = try? Data(contentsOf: url) {
                                    if data.count <= 1_000_000 {
                                        let base64 = data.base64EncodedString()
                                        FirestoreManager.shared.addDocument(
                                            toCaseId: targetId,
                                            fileName: url.lastPathComponent,
                                            fileType: url.pathExtension.uppercased(),
                                            fileURL: nil,
                                            fileBase64: base64
                                        )
                                    }
                                }
                            }
                            
                            if editingCase == nil {
                                // Send notification to the client only for NEW cases
                                let clientNotification = FBNotification(
                                    title: "New Case Created",
                                    body: "\(lawyerName) created '\(modifiedCase.title)' for you.",
                                    type: "case",
                                    timestamp: Date(),
                                    relatedId: targetId
                                )
                                FirestoreManager.shared.addNotification(clientNotification, toUserId: selectedClientId)
                            }

                            NotificationManager.shared.scheduleNotification(
                                title: editingCase == nil ? "Case Added" : "Case Updated", 
                                body: "Successfully \(editingCase == nil ? "created" : "updated") active case: \(modifiedCase.title)"
                            )
                            dismiss()
                        }
                        .disabled(isUpdating || caseTitle.isEmpty || selectedClientId.isEmpty)
                        .opacity((isUpdating || caseTitle.isEmpty || selectedClientId.isEmpty) ? 0.6 : 1.0)
                        .overlay {
                            if isUpdating {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        .padding(.top, 20)
                        
                        Color.clear.frame(height: 140)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
        }
        .onChange(of: selectedItems) { _, items in
            Task {
                selectedImages.removeAll()
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImages.append(image)
                    }
                }
            }
        }
        .fileImporter(isPresented: $isFileImporterPresented, allowedContentTypes: [.pdf, .plainText], allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                selectedFiles.append(contentsOf: urls)
            case .failure(let error):
                print("DEBUG: File selection error: \(error)")
            }
        }
        .ignoresSafeArea(edges: .top)
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
