import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct UploadAdvisoryView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Form State
    @State private var category: String = "Family Law"
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var visibility: String = "Public"
    @State private var tagInput: String = ""
    @State private var tags: [String] = []
    
    // MARK: - Upload State
    @State private var selectedFile: URL? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var isFileImporterPresented = false
    @State private var isPhotosPickerPresented = false
    @State private var isCameraPresented = false
    @State private var showUploadDialog = false
    @State private var photosPickerItem: PhotosPickerItem? = nil

    private let categories = ["Family Law", "Criminal Law", "Property Law", "Corporate Law"]
    private let visibilities = ["Public", "Private"]

    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Background Blob
            GreenBlobBackground(style: .lawyer)
                .frame(height: 350)
                .offset(y: -50)
            
            VStack(spacing: 0) {
                // MARK: Custom Header
                LawMateNavigationBar(
                    title: "Upload Advisory",
                    showBack: true,
                    onBack: { dismiss() }
                )
                .padding(.top, 65)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // MARK: Title & Subtitle Section
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Upload Advisory Document")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.lmPrimary)
                            Text("Share helpful legal documents for public access")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.lmTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // MARK: Document Info Section
                        VStack(spacing: 20) {
                            // Category Picker
                            pickerRow(title: "Category", icon: "tag.fill") {
                                Menu {
                                    Picker("", selection: $category) {
                                        ForEach(categories, id: \.self) { cat in
                                            Text(cat).tag(cat)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(category)
                                            .font(.system(size: 14, weight: .bold))
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 10))
                                    }
                                    .foregroundColor(.lmPrimary)
                                    .fixedSize(horizontal: true, vertical: false)
                                }
                            }
                            
                            LawMateTextField(icon: "doc.text.fill", placeholder: "Enter document title", text: $title)
                        }
                        
                        // MARK: Description
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Description")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.lmTextSecondary)
                                .padding(.leading, 4)
                            
                            TextEditor(text: $description)
                                .frame(height: 100)
                                .padding(12)
                                .background(Color.white.opacity(0.1))
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }

                        // MARK: Upload Card Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Resource Attachment")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.lmTextSecondary)
                                .padding(.leading, 4)
                            
                            if selectedFile == nil && selectedImage == nil {
                                Button {
                                    showUploadDialog = true
                                } label: {
                                    uploadPlaceholder
                                }
                            } else {
                                filePreview
                            }
                        }

                        // MARK: Visibility & Tags
                        VStack(spacing: 24) {
                            // Visibility
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Visibility Settings")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.lmTextSecondary)
                                    .padding(.leading, 4)
                                
                                Picker("", selection: $visibility) {
                                    ForEach(visibilities, id: \.self) { vis in
                                        Text(vis).tag(vis)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }

                            // Tags
                            VStack(alignment: .leading, spacing: 12) {
                                // Suggested Tags
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        let suggestedTags = ["Divorce", "Custody", "Contract", "Property", "Criminal", "Civil", "Corporate", "Lease", "Agreement"]
                                        ForEach(suggestedTags, id: \.self) { tag in
                                            Button {
                                                if !tags.contains(tag) {
                                                    tags.append(tag)
                                                }
                                            } label: {
                                                Text(tag)
                                                    .font(.system(size: 12, weight: .bold))
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.lmPrimary.opacity(0.1))
                                                    .foregroundColor(.lmPrimary)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                    .padding(.leading, 4)
                                }
                                
                                LawMateTextField(icon: "tag.circle.fill", placeholder: "Or enter custom tags...", text: $tagInput)
                                    .onChange(of: tagInput) { _, newValue in
                                        if newValue.contains(",") {
                                            let newTags = newValue.components(separatedBy: ",")
                                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                                .filter { !$0.isEmpty }
                                            for tag in newTags {
                                                if !tags.contains(tag) {
                                                    tags.append(tag)
                                                }
                                            }
                                            tagInput = ""
                                        }
                                    }
                                
                                if !tags.isEmpty {
                                    FlowLayout(spacing: 8) {
                                        ForEach(tags, id: \.self) { tag in
                                            tagChip(text: tag)
                                        }
                                    }
                                }
                            }
                        }

                        // MARK: Publish Button
                        LawMatePrimaryButton(title: "Publish Document") {
                            if let url = selectedFile {
                                // 1MB Validation for Database Storage
                                if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                                   let fileSize = attributes[.size] as? Int64,
                                   fileSize > 1_000_000 {
                                    ToastManager.shared.show(title: "File Too Large", message: "Document must be under 1MB for database storage.", type: .error)
                                    return
                                }
                                
                                ToastManager.shared.show(title: "Publishing...", message: "Uploading your document.", type: .info)
                                
                                FirestoreManager.shared.uploadAdvisoryDocument(
                                    title: title,
                                    category: category,
                                    description: description,
                                    tags: tags,
                                    visibility: visibility,
                                    lawyerName: AuthService.shared.currentUser?.fullName ?? "LawMate Attorney",
                                    lawyerId: AuthService.shared.currentUser?.id ?? "",
                                    tempURL: url
                                ) { success, errorMessage in
                                    DispatchQueue.main.async {
                                        if success {
                                            ToastManager.shared.show(title: "Document Published", message: "Your advisory document is now live.", type: .success)
                                            NotificationManager.shared.scheduleNotification(title: "Document Published", body: "Successfully published \(title)")
                                            dismiss()
                                        } else {
                                            ToastManager.shared.show(title: "Upload Failed", message: errorMessage ?? "Could not publish document.", type: .error)
                                        }
                                    }
                                }
                            } else if let image = selectedImage {
                                // Save image to temporary file first
                                if let data = image.jpegData(compressionQuality: 0.8) {
                                    if data.count > 1_000_000 {
                                        ToastManager.shared.show(title: "Image Too Large", message: "Image must be under 1MB for database storage.", type: .error)
                                        return
                                    }
                                    
                                    ToastManager.shared.show(title: "Publishing...", message: "Uploading your document.", type: .info)
                                    
                                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                                    try? data.write(to: tempURL)
                                    FirestoreManager.shared.uploadAdvisoryDocument(
                                        title: title,
                                        category: category,
                                        description: description,
                                        tags: tags,
                                        visibility: visibility,
                                        lawyerName: AuthService.shared.currentUser?.fullName ?? "LawMate Attorney",
                                        lawyerId: AuthService.shared.currentUser?.id ?? "",
                                        tempURL: tempURL
                                    ) { success, errorMessage in
                                        DispatchQueue.main.async {
                                            if success {
                                                ToastManager.shared.show(title: "Document Published", message: "Your advisory document is now live.", type: .success)
                                                NotificationManager.shared.scheduleNotification(title: "Document Published", body: "Successfully published \(title)")
                                                dismiss()
                                            } else {
                                                ToastManager.shared.show(title: "Upload Failed", message: errorMessage ?? "Could not publish document.", type: .error)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .disabled(title.isEmpty || (selectedFile == nil && selectedImage == nil))
                        .opacity((title.isEmpty || (selectedFile == nil && selectedImage == nil)) ? 0.5 : 1.0)
                        
                        Color.clear.frame(height: 140)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
        }
        
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .confirmationDialog("Choose Source", isPresented: $showUploadDialog) {
            Button("Files") { isFileImporterPresented = true }
            Button("Photo Library") { isPhotosPickerPresented = true }
            Button("Camera") { isCameraPresented = true }
            Button("Cancel", role: .cancel) {}
        }
        .fileImporter(isPresented: $isFileImporterPresented, allowedContentTypes: [.pdf, .rtf, .plainText, .image, .item], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                
                // Start accessing security-scoped resource
                let shouldStopAccessing = url.startAccessingSecurityScopedResource()
                defer { if shouldStopAccessing { url.stopAccessingSecurityScopedResource() } }
                
                // Copy to a stable local temporary location immediately
                let tempDir = FileManager.default.temporaryDirectory
                let localURL = tempDir.appendingPathComponent(UUID().uuidString + "_" + url.lastPathComponent)
                
                do {
                    if FileManager.default.fileExists(atPath: localURL.path) {
                        try FileManager.default.removeItem(at: localURL)
                    }
                    try FileManager.default.copyItem(at: url, to: localURL)
                    selectedFile = localURL
                    selectedImage = nil
                    print("Successfully cached file locally: \(localURL.lastPathComponent)")
                } catch {
                    print("Failed to cache file: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print("File selection failed: \(error.localizedDescription)")
            }
        }
        .photosPicker(isPresented: $isPhotosPickerPresented, selection: $photosPickerItem, matching: .images)
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                    selectedFile = nil
                }
            }
        }
        .sheet(isPresented: $isCameraPresented) {
            ImagePicker(sourceType: .camera, selectedImage: $selectedImage)
        }
    }

    // MARK: - Subviews

    private var uploadPlaceholder: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.lmPrimary.opacity(0.1))
                    .frame(width: 64, height: 64)
                Image(systemName: "arrow.up.doc.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.lmPrimary)
            }
            
            VStack(spacing: 4) {
                Text("Upload File")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.lmPrimary)
                Text("PDF, DOCX, JPG, PNG")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.lmTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.white.opacity(0.1))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundColor(.lmPrimary.opacity(0.3))
        )
    }

    private var filePreview: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.lmPrimary.opacity(0.1))
                    .frame(width: 48, height: 48)
                Image(systemName: selectedImage != nil ? "photo.fill" : "doc.fill")
                    .foregroundColor(.lmPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedFile?.lastPathComponent ?? "Image.jpg")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lmPrimary)
                    .lineLimit(1)
                Text(selectedImage != nil ? "Image/HEIC" : "Document/PDF")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.lmTextSecondary)
            }
            
            Spacer()
            
            Button {
                selectedFile = nil
                selectedImage = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red.opacity(0.7))
                    .font(.system(size: 24))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func tagChip(text: String) -> some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.system(size: 12, weight: .bold))
            Button {
                tags.removeAll { $0 == text }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .foregroundColor(.white)
        .background(Color.lmPrimary)
        .clipShape(Capsule())
    }

    private func pickerRow<Content: View>(title: String, icon: String, @ViewBuilder content: @escaping () -> Content) -> some View {
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
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 100))
        .overlay(RoundedRectangle(cornerRadius: 100).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

// MARK: - Helpers

struct FlowLayout: View {
    let spacing: CGFloat
    let content: [AnyView]
    
    init<Views: View>(spacing: CGFloat, @ViewBuilder content: @escaping () -> Views) {
        self.spacing = spacing
        // Simplification for the purpose of the UI/UX demonstration
        self.content = [AnyView(content())]
    }
    
    var body: some View {
        // Using a simple HStack for this demo, usually would use a more complex layout
        // to handle wrapping, but for a one-shot UI implementation this works.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                ForEach(0..<content.count, id: \.self) { i in
                    content[i]
                }
            }
        }
    }
}


#Preview {
    UploadAdvisoryView()
}
