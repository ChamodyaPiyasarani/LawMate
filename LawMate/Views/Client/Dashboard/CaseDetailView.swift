import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Case Detail View (Progress & Documents)
struct CaseDetailView: View {
    @State var clientCase: FBLegalCase
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firestore: FirestoreManager
    @Binding var navPath: NavigationPath
    @Binding var activeConversation: FBConversation?
    
    private var currentCase: FBLegalCase {
        firestore.cases.first(where: { $0.id == clientCase.id }) ?? clientCase
    }
    
    @State private var selectedTab = 0 // 0: Progress, 1: Documents
    @State private var selectedDocument: FBDocument? = nil
    
    // Upload State
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var isUploading = false
    @State private var activeStageIndex: Int? = nil
    @State private var showFilePicker = false
    @State private var showScanner = false
    @State private var showAddHearingSheet = false
    @State private var newHearingDate = Date()
    @State private var newHearingLocation = ""
    
    @State private var selectedCategory = "Other"
    @State private var targetGroupId: String? = nil
    @State private var targetVersion: Int = 1
    
    private let documentCategories = ["Evidence", "Contract", "Court Order", "Identity", "Other"]
    
    private var isLawyer: Bool {
        AuthService.shared.currentUser?.role == .lawyer
    }
    
    private var isCaseAvailable: Bool {
        firestore.cases.contains(where: { $0.id == clientCase.id })
    }

    var body: some View {
        Group {
            if isCaseAvailable {
                mainContent
            } else {
                Color.lmBackground
                    .onAppear {
                        ToastManager.shared.show(
                            title: "Case Unavailable",
                            message: "This case has been deleted or is no longer available.",
                            type: .error
                        )
                        dismiss()
                    }
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if let caseId = clientCase.id {
                FirestoreManager.shared.listenForDocuments(forCaseId: caseId)
            }
        }
        .sheet(item: $selectedDocument) { doc in
            let dummyDoc = FBAdvisoryDocument(
                id: doc.id ?? UUID().uuidString,
                title: doc.fileName,
                description: "",
                category: "Case Document",
                tags: [],
                lawyerName: "",
                date: ISO8601DateFormatter().string(from: doc.uploadedAt),
                fileType: doc.fileType,
                fileURL: doc.fileURL,
                lawyerId: "",
                visibility: "Private",
                fileBase64: doc.fileBase64
            )
            PDFKitViewerSheet(document: dummyDoc)
        }
        .onChange(of: selectedImage) { _, _ in
            handleImageUpload()
        }
        .sheet(isPresented: $showScanner) {
            DocumentScannerView(isPresented: $showScanner) { urls in
                handleScannedDocuments(urls)
            } onError: { error in
                ToastManager.shared.show(title: "Scanning Error", message: error.localizedDescription, type: .error)
            }
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.pdf, .png, .jpeg]) { result in
            handleFileURLUpload(result: result)
        }
        .sheet(isPresented: $showAddHearingSheet) {
            addHearingSheet
        }
    }

    private var mainContent: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Green blob top-left
            GreenBlobBackground(style: .client)
                .frame(height: 300)
            
            VStack(spacing: 0) {
                // MARK: Custom Header
                LawMateNavigationBar(
                    title: "Case Details",
                    showBack: true,
                    showNotification: !isLawyer,
                    showCamera: isLawyer,
                    onBack: { dismiss() },
                    onCamera: { showScanner = true }
                )
                .padding(.top, 65)
                .zIndex(10)
                
                // MARK: Case Header Summary
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentCase.caseNumber)
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.lmPrimary.opacity(0.5))
                        Text(currentCase.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.lmPrimary)
                    }
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(currentCase.progressProgress * 100))%")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.lmPrimary)
                        Text("Progress")
                            .font(.system(size: 10))
                            .foregroundColor(.lmTextSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                if let desc = currentCase.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 13))
                        .foregroundColor(.lmTextSecondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                }
                
                
                // MARK: Segmented Control
                HStack(spacing: 0) {
                    TabButton(title: "Progress", isSelected: selectedTab == 0) {
                        withAnimation(.spring()) { selectedTab = 0 }
                    }
                    TabButton(title: "Documents", isSelected: selectedTab == 1) {
                        withAnimation(.spring()) { selectedTab = 1 }
                    }
                }
                .padding(4)
                .background(Color.black.opacity(0.05))
                .clipShape(Capsule())
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                // MARK: Tab Content
                ScrollView(showsIndicators: false) {
                    if selectedTab == 0 {
                        progressSection
                            .transition(.opacity)
                    } else {
                        documentsSection
                            .transition(.opacity)
                    }
                    
                    Color.clear.frame(height: 120)
                }
            }
            
            
            if isUploading {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Uploading file...")
                            .font(.lmBody)
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    private var addHearingSheet: some View {
        NavigationStack {
            Form {
                Section("Hearing Details") {
                    DatePicker("Date & Time", selection: $newHearingDate)
                    TextField("Location (Court/Room)", text: $newHearingLocation)
                }
            }
            .navigationTitle("Add Hearing Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddHearingSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNewHearing()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func saveNewHearing() {
        var updatedCase = currentCase
        let newHearing = FBHearingDate(date: newHearingDate, location: newHearingLocation, notes: "")
        
        // Add and sort
        updatedCase.hearings.append(newHearing)
        updatedCase.hearings.sort { $0.date < $1.date }
        
        // Also update legacy array for safety
        updatedCase.hearingDates.append(newHearingDate)
        updatedCase.hearingDates.sort()
        updatedCase.hearingDate = updatedCase.hearings.first?.date
        
        FirestoreManager.shared.updateCase(updatedCase) { success in
            if success {
                showAddHearingSheet = false
                newHearingLocation = ""
                newHearingDate = Date()
                ToastManager.shared.show(title: "Hearing Added", message: "Successfully added new hearing date.", type: .success)
            }
        }
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(currentCase.stages.enumerated()), id: \.offset) { index, stage in
                let isActive = !stage.isCompleted && (index == 0 || currentCase.stages[index-1].isCompleted)
                
                VStack(alignment: .leading, spacing: 0) {
                    TimelineNode(
                        index: index,
                        stage: stage,
                        isLast: index == currentCase.stages.count - 1,
                        isActive: isActive,
                        canEdit: isLawyer && (stage.isCompleted || (index == 0 || currentCase.stages[index-1].isCompleted)),
                        onToggle: {
                            // Sequential logic
                            let isNext = !stage.isCompleted && (index == 0 || currentCase.stages[index-1].isCompleted)
                            let isLastCompleted = stage.isCompleted && (index == currentCase.stages.count - 1 || !currentCase.stages[index+1].isCompleted)
                            
                            if isNext || isLastCompleted {
                                FirestoreManager.shared.updateCaseStage(caseId: currentCase.id ?? "", stageIndex: index, isCompleted: !stage.isCompleted)
                            } else {
                                ToastManager.shared.show(title: "Sequential Progress", message: "Please complete previous steps first.", type: .warning)
                            }
                        },
                        onUpload: {
                            activeStageIndex = index
                            showFilePicker = true
                        }
                    )
                    
                    // NEW: Content below node (fixes overlap)
                    VStack(alignment: .leading, spacing: 12) {
                        // Upload Buttons (Lawyer only)
                        if isLawyer && (isActive || stage.isCompleted) {
                            StageUploadButton(
                                selectedItem: $selectedImage,
                                selectedCategory: $selectedCategory,
                                categories: documentCategories
                            ) {
                                activeStageIndex = index
                                showFilePicker = true
                            }
                            .padding(.top, 12)
                        }
                        
                        // Show Attached Hearings if this is a hearing stage
                        if stage.title.lowercased().contains("hearing") {
                            VStack(alignment: .leading, spacing: 8) {
                                if !currentCase.hearings.isEmpty {
                                    ForEach(currentCase.hearings.sorted(by: { $0.date < $1.date })) { hearing in
                                        HStack {
                                            Image(systemName: "calendar")
                                                .font(.system(size: 10))
                                            Text(hearing.date, style: .date)
                                                .font(.system(size: 11, weight: .bold))
                                            Text(hearing.date, style: .time)
                                                .font(.system(size: 11))
                                            Spacer()
                                            if !hearing.location.isEmpty {
                                                Image(systemName: "mappin")
                                                    .font(.system(size: 10))
                                                Text(hearing.location)
                                                    .font(.system(size: 10))
                                                    .lineLimit(1)
                                            }
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(Color.lmPrimary.opacity(0.05))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                } else if !currentCase.hearingDates.isEmpty {
                                    let uniqueDates = deduplicateDatesByDay(currentCase.hearingDates)
                                    ForEach(uniqueDates.sorted(), id: \.self) { date in
                                        HStack {
                                            Image(systemName: "calendar")
                                                .font(.system(size: 10))
                                            Text(date, style: .date)
                                                .font(.system(size: 11, weight: .bold))
                                            Spacer()
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(Color.lmPrimary.opacity(0.05))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                                
                                if isLawyer {
                                    Button {
                                        // Open a simple sheet or just update a state to show a picker
                                        showAddHearingSheet = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add Hearing Date")
                                        }
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.lmPrimary)
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }

                        // Show Attached Files if any
                        let stageDocs = firestore.caseDocuments.filter { $0.stageIndex == index }
                        if !stageDocs.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Shared Files:")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.lmPrimary.opacity(0.4))
                                    .textCase(.uppercase)
                                    .padding(.top, (isLawyer && (isActive || stage.isCompleted)) ? 4 : 12)
                                
                                ForEach(stageDocs) { doc in
                                    Button {
                                        selectedDocument = doc
                                    } label: {
                                        HStack {
                                            Image(systemName: doc.fileType == "PDF" ? "doc.fill" : "photo.fill")
                                                .font(.system(size: 12))
                                            Text(doc.fileName)
                                                .font(.system(size: 12, weight: .bold))
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 10, weight: .bold))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.leading, 42)
                    .padding(.bottom, 30) // Space before next node
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.top, 10)
    }
    
    // MARK: - Documents Section
    private var documentsSection: some View {
        let groupedDocs = Dictionary(grouping: firestore.caseDocuments) { $0.groupId ?? $0.id ?? "unknown" }
        let sortedGroups = groupedDocs.keys.sorted { key1, key2 in
            let latest1 = groupedDocs[key1]?.map(\.uploadedAt).max() ?? Date.distantPast
            let latest2 = groupedDocs[key2]?.map(\.uploadedAt).max() ?? Date.distantPast
            return latest1 > latest2
        }

        return VStack(spacing: 16) {
            if sortedGroups.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.lmPrimary.opacity(0.2))
                    Text("No documents uploaded yet")
                        .font(.custom("Outfit-Medium", size: 16))
                        .foregroundColor(.lmTextSecondary)
                }
                .padding(.top, 80)
            } else {
                ForEach(sortedGroups, id: \.self) { groupId in
                    let docs = (groupedDocs[groupId] ?? []).sorted { $0.version > $1.version }
                    if let latest = docs.first {
                        DocumentGroupRow(
                            latestDoc: latest,
                            versions: docs,
                            isLawyer: isLawyer,
                            onSelect: { selectedDocument = $0 },
                            onAddVersion: {
                                targetGroupId = groupId
                                targetVersion = latest.version + 1
                                selectedCategory = latest.category
                                showFilePicker = true
                            }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Upload Helpers
    @State private var showUploadOptions = false
    
    private func handleImageUpload() {
        guard let item = selectedImage else { return }
        isUploading = true
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let data = data {
                        uploadData(data, ext: "jpg")
                    } else {
                        isUploading = false
                        ToastManager.shared.show(title: "Upload Failed", message: "Could not process image data.", type: .error)
                    }
                case .failure(let error):
                    isUploading = false
                    ToastManager.shared.show(title: "Upload Failed", message: error.localizedDescription, type: .error)
                }
                selectedImage = nil
            }
        }
    }
    
    private func handleFileURLUpload(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            isUploading = true
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            
            do {
                let data = try Data(contentsOf: url)
                uploadData(data, ext: url.pathExtension)
            } catch {
                isUploading = false
                ToastManager.shared.show(title: "Access Error", message: "Could not read the selected file. Please try again.", type: .error)
                print("DEBUG: File reading error: \(error)")
            }
        case .failure(let error):
            ToastManager.shared.show(title: "Selection Error", message: error.localizedDescription, type: .error)
        }
    }
    
    private func handleScannedDocuments(_ urls: [URL]) {
        for url in urls {
            if let data = try? Data(contentsOf: url) {
                uploadData(data, ext: "jpg")
            }
        }
    }
    
    private func uploadData(_ data: Data, ext: String) {
        // Attempt ID recovery if missing
        var caseId = clientCase.id
        if caseId == nil || caseId == "temp" || caseId == "unknown" {
            if let matchedCase = FirestoreManager.shared.cases.first(where: { $0.caseNumber == clientCase.caseNumber }) {
                caseId = matchedCase.id
                print("DEBUG: Recovered missing Case ID: \(caseId ?? "none")")
            }
        }
        
        guard let finalId = caseId, !finalId.isEmpty, finalId != "temp", finalId != "unknown" else {
            isUploading = false
            ToastManager.shared.show(title: "Sync Error", message: "Case data is still synchronizing. Please wait a moment.", type: .error)
            return
        }
        
        // 1MB Validation for Database Storage
        if data.count > 1_000_000 {
            isUploading = false
            ToastManager.shared.show(title: "File Too Large", message: "Document must be under 1MB for database storage.", type: .error)
            return
        }
        
        let base64String = data.base64EncodedString()
        let displayName = "Doc_\(Int.random(in: 1000...9999)).\(ext.isEmpty ? "bin" : ext)"
        let type = ext.uppercased() == "PDF" ? "PDF" : "IMG"
        
        FirestoreManager.shared.addDocument(
            toCaseId: finalId,
            fileName: displayName,
            fileType: type,
            fileURL: nil,
            fileBase64: base64String,
            stageIndex: activeStageIndex,
            category: selectedCategory,
            version: targetVersion,
            groupId: targetGroupId
        )
        
        ToastManager.shared.show(title: "Success", message: targetVersion > 1 ? "New version uploaded." : "Document uploaded successfully.", type: .success)
        isUploading = false
        
        // Reset states
        selectedCategory = "Other"
        targetGroupId = nil
        targetVersion = 1
    }

    private func deduplicateDatesByDay(_ dates: [Date]) -> [Date] {
        var uniqueDates: [Date] = []
        for date in dates {
            if !uniqueDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: date) }) {
                uniqueDates.append(date)
            }
        }
        return uniqueDates
    }
}

// MARK: - Helper Components
struct StageUploadButton: View {
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var selectedCategory: String
    let categories: [String]
    var onFile: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category Picker
            HStack {
                Text("Category:")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.lmTextSecondary)
                
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .tint(.lmPrimary)
                .scaleEffect(0.9)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)

            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.fill")
                        Text("Add Image")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.lmPrimary)
                    .clipShape(Capsule())
                    .shadow(color: Color.lmPrimary.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                
                Button(action: onFile) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.fill")
                        Text("Add PDF")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.lmPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.lmPrimary.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
    }
}
