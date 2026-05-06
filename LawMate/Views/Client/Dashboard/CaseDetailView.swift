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
    
    private var isLawyer: Bool {
        AuthService.shared.currentUser?.role == .lawyer
    }
    
    var body: some View {
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
                    onNotification: {
                        navPath.append(ClientHomeView.AppRoute.notifications)
                    },
                    onCamera: { showScanner = true }
                )
                .padding(.top, 54)
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
                
                if currentCase.hearingDates.count > 0 {
                    VStack(spacing: 8) {
                        ForEach(currentCase.hearingDates.sorted(), id: \.self) { date in
                            HStack {
                                Image(systemName: "calendar")
                                Text("Hearing: \(date, style: .date)")
                                Spacer()
                                if let address = currentCase.address {
                                    Image(systemName: "mappin")
                                    Text(address).lineLimit(1)
                                }
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.lmPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.lmPrimary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                } else if let hDate = currentCase.hearingDate {
                    HStack {
                        Image(systemName: "calendar")
                        Text("Hearing: \(hDate, style: .date)")
                        Spacer()
                        if let address = currentCase.address {
                            Image(systemName: "mappin")
                            Text(address).lineLimit(1)
                        }
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.lmPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.lmPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
            .ignoresSafeArea(edges: .top)
            
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
                            StageUploadButton(selectedItem: $selectedImage) {
                                activeStageIndex = index
                                showFilePicker = true
                            }
                            .padding(.top, 12)
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
        VStack(spacing: 16) {
            ForEach(firestore.caseDocuments) { doc in
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.lmPrimary.opacity(0.1))
                            .frame(width: 52, height: 52)
                        
                        Image(systemName: doc.fileType == "PDF" ? "doc.fill" : "photo.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.lmPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(doc.fileName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.lmPrimary)
                        Text("Step \( (doc.stageIndex ?? 0) + 1 ) • \(doc.uploadedAt, style: .date)")
                            .font(.system(size: 12))
                            .foregroundColor(.lmTextSecondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        selectedDocument = doc
                    } label: {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.lmPrimary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            }
            
            if firestore.caseDocuments.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.lmPrimary.opacity(0.2))
                    Text("No documents uploaded yet")
                        .font(.custom("Outfit-Medium", size: 16))
                        .foregroundColor(.lmTextSecondary)
                }
                .padding(.top, 80)
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
            stageIndex: activeStageIndex
        )
        
        ToastManager.shared.show(title: "Success", message: "Document uploaded successfully.", type: .success)
        isUploading = false
    }
}

// MARK: - Helper Components
struct StageUploadButton: View {
    @Binding var selectedItem: PhotosPickerItem?
    var onFile: () -> Void
    
    var body: some View {
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
