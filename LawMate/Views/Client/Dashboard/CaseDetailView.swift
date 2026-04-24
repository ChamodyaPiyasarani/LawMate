import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Case Detail View (Progress & Documents)
struct CaseDetailView: View {
    @State var clientCase: FBLegalCase
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0 // 0: Progress, 1: Documents
    @State private var documents: [FBDocument] = []
    @State private var selectedDocument: FBDocument? = nil
    
    // Upload State
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var isUploading = false
    @State private var activeStageIndex: Int? = nil
    @State private var showFilePicker = false
    
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
                    showNotification: true,
                    onBack: { dismiss() }
                )
                .padding(.top, 64)
                .zIndex(10)
                
                // MARK: Case Header Summary
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(clientCase.caseNumber)
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.lmPrimary.opacity(0.5))
                        Text(clientCase.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.lmPrimary)
                    }
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(clientCase.progressProgress * 100))%")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.lmPrimary)
                        Text("Progress")
                            .font(.system(size: 10))
                            .foregroundColor(.lmTextSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
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
            refreshDocuments()
        }
        .sheet(item: $selectedDocument) { doc in
            if let urlString = doc.fileURL, let url = URL(string: urlString) {
                LawMateDocumentViewer(title: doc.fileName, url: url)
            } else {
                Text("Error: Document URL is missing.")
                    .padding()
            }
        }
        .onChange(of: selectedImage) { _, _ in
            handleImageUpload()
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.pdf, .png, .jpeg]) { result in
            handleFileURLUpload(result: result)
        }
    }
    
    private func refreshDocuments() {
        FirestoreManager.shared.fetchDocuments(forCaseId: clientCase.id ?? "") { fetchedDocs in
            self.documents = fetchedDocs
        }
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(clientCase.stages.enumerated()), id: \.offset) { index, stage in
                let isActive = !stage.isCompleted && (index == 0 || clientCase.stages[index-1].isCompleted)
                let isLawyer = AuthService.shared.currentUser?.role == .lawyer
                
                VStack(alignment: .leading, spacing: 0) {
                    TimelineNode(
                        index: index,
                        stage: stage,
                        isLast: index == clientCase.stages.count - 1,
                        isActive: isActive,
                        canEdit: isLawyer,
                        onToggle: {
                            FirestoreManager.shared.updateCaseStage(caseId: clientCase.id ?? "", stageIndex: index, isCompleted: !stage.isCompleted)
                            clientCase.stages[index].isCompleted.toggle()
                        },
                        onUpload: {
                            activeStageIndex = index
                            showUploadOptions = true
                        }
                    )
                    .overlay(
                        VStack(alignment: .leading, spacing: 12) {
                            // Upload Buttons (Lawyer only)
                            if isLawyer && (isActive || stage.isCompleted) {
                                StageUploadButton(selectedItem: $selectedImage) {
                                    activeStageIndex = index
                                    showFilePicker = true
                                }
                                .padding(.top, 40)
                            }
                            
                            // Show Attached Files if any
                            let stageDocs = documents.filter { $0.stageIndex == index }
                            if !stageDocs.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Shared Files:")
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundColor(.lmPrimary.opacity(0.4))
                                        .textCase(.uppercase)
                                    
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
                                .padding(.top, (isLawyer && (isActive || stage.isCompleted)) ? 0 : 40)
                            }
                        }
                        .padding(.leading, 42)
                        .padding(.top, 50)
                        , alignment: .topLeading
                    )
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.top, 10)
    }
    
    // MARK: - Documents Section
    private var documentsSection: some View {
        VStack(spacing: 16) {
            ForEach(documents) { doc in
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
            
            if documents.isEmpty {
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
        
        let storageName = "\(UUID().uuidString).\(ext.isEmpty ? "bin" : ext)"
        let displayName = "Doc_\(Int.random(in: 1000...9999)).\(ext.isEmpty ? "bin" : ext)"
        let type = ext.uppercased() == "PDF" ? "PDF" : "IMG"
        
        FirestoreManager.shared.uploadFile(data: data, path: "cases/\(finalId)/docs", fileName: storageName) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    FirestoreManager.shared.addDocument(toCaseId: finalId, fileName: displayName, fileType: type, fileURL: url, stageIndex: activeStageIndex)
                    ToastManager.shared.show(title: "Success", message: "Document uploaded successfully.", type: .success)
                    refreshDocuments()
                    isUploading = false
                case .failure(let error):
                    isUploading = false
                    ToastManager.shared.show(title: "Upload Failed", message: error.localizedDescription, type: .error)
                    print("Upload failed: \(error)")
                }
            }
        }
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
