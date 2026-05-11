import SwiftUI

struct DocumentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPDFViewer = false
    let document: FBAdvisoryDocument
    
    @EnvironmentObject var firestore: FirestoreManager
    @State private var localURL: URL? = nil
    @State private var isLoading = false
    
    private var isDocumentAvailable: Bool {
        firestore.advisoryDocuments.contains(where: { $0.id == document.id })
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                if isDocumentAvailable {
                    mainContent
                } else {
                    unavailableState
                }
            }
        }
        .onAppear {
            prepareDocument()
        }
        .sheet(isPresented: $showPDFViewer) {
            PDFKitViewerSheet(document: document)
        }
    }

    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: Header Section
                HStack(alignment: .top) {
                    HStack(alignment: .center, spacing: 12) {
                        // File Icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(iconColor.opacity(0.1))
                                .frame(width: 40, height: 40)
                            Image(systemName: iconName)
                                .font(.system(size: 18))
                                .foregroundColor(iconColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            // Category first
                            Text(document.category)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.lmPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.lmPrimary.opacity(0.06))
                                .clipShape(Capsule())
                            
                            // Type second
                            Text(document.fileType)
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(iconColor.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    // Action Buttons (Top Right Corner)
                    HStack(spacing: 10) {
                        // View Button
                        Button {
                            showPDFViewer = true
                        } label: {
                            actionIconButton(icon: "eye.fill", bgColor: Color.green.opacity(0.08), iconColor: .green)
                        }
                        
                        if let url = localURL {
                            // Download
                            ShareLink(item: url) {
                                actionIconButton(icon: "arrow.down.to.line.circle.fill", bgColor: Color.blue.opacity(0.08), iconColor: .blue)
                            }
                            
                            // Share
                            ShareLink(item: url) {
                                actionIconButton(icon: "square.and.arrow.up.fill", bgColor: Color.orange.opacity(0.08), iconColor: .orange)
                            }
                        }
                    }
                }
                .padding(.top, 32)
                
                Text(document.title)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.lmPrimary)
                    .lineLimit(3)
                
                HStack(spacing: 12) {
                    metadataPill(icon: "person.fill", text: document.lawyerName)
                    metadataPill(icon: "calendar", text: document.date)
                }
                
                // MARK: Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("About this document")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    Text(document.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.lmTextSecondary)
                        .lineSpacing(3)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.3))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
                
                // MARK: Tags
                if !document.tags.isEmpty {
                    DocumentTagsFlowLayout(spacing: 6) {
                        ForEach(document.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.lmPrimary.opacity(0.7))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.lmPrimary.opacity(0.04))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func metadataPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(.lmTextSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.06))
        .clipShape(Capsule())
    }
    
    private func actionIconButton(icon: String, bgColor: Color, iconColor: Color) -> some View {
        ZStack {
            Circle()
                .fill(bgColor)
                .frame(width: 38, height: 38)
                .overlay(
                    Circle()
                        .stroke(iconColor.opacity(0.1), lineWidth: 1)
                )
            
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(iconColor)
        }
    }
    
    private var unavailableState: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.red.opacity(0.5))
            Text("Document Unavailable")
                .font(.system(size: 18, weight: .bold))
            Button("Dismiss") { dismiss() }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.lmPrimary)
        }
        .frame(maxHeight: .infinity)
    }

    private func prepareDocument() {
        isLoading = true
        if let base64 = document.fileBase64, let data = Data(base64Encoded: base64) {
            decodeAndSave(data: data)
            return
        }
        if let urlString = document.fileURL, let url = URL(string: urlString) {
            if url.isFileURL {
                self.localURL = url
                self.isLoading = false
            } else {
                downloadDocument(url: url)
            }
            return
        }
        isLoading = false
    }
    
    private func decodeAndSave(data: Data) {
        DispatchQueue.global(qos: .userInitiated).async {
            let tempDir = FileManager.default.temporaryDirectory
            let extensionName = document.fileType.lowercased()
            let fileName = (document.id ?? UUID().uuidString) + "." + (extensionName.isEmpty ? "pdf" : extensionName)
            let fileURL = tempDir.appendingPathComponent(fileName)
            try? data.write(to: fileURL)
            DispatchQueue.main.async {
                self.localURL = fileURL
                self.isLoading = false
            }
        }
    }
    
    private func downloadDocument(url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                self.decodeAndSave(data: data)
            } else {
                DispatchQueue.main.async { self.isLoading = false }
            }
        }.resume()
    }
    
    var iconName: String {
        switch document.fileType {
        case "PDF": return "doc.text.fill"
        case "DOCX": return "doc.fill"
        default: return "photo.fill"
        }
    }
    
    var iconColor: Color {
        switch document.fileType {
        case "PDF": return .red
        case "DOCX": return .blue
        default: return .orange
        }
    }
}

// Simple DocumentTagsFlowLayout for Tags
struct DocumentTagsFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > width {
                currentX = 0
                currentY += maxHeight + spacing
                maxHeight = 0
            }
            currentX += size.width + spacing
            maxHeight = max(maxHeight, size.height)
            totalHeight = currentY + maxHeight
        }
        return CGSize(width: width, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var maxHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += maxHeight + spacing
                maxHeight = 0
            }
            view.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            maxHeight = max(maxHeight, size.height)
        }
    }
}

#Preview {
    DocumentDetailView(document: FBAdvisoryDocument(
        title: "Divorce Proceedings Guide - 2024 Edition",
        description: "A comprehensive guide on what to expect during divorce proceedings in Sri Lanka.",
        category: "Family Law",
        tags: ["divorce", "family", "guide"],
        lawyerName: "Sanduni Fernando",
        date: "Apr 20, 2024",
        fileType: "PDF"
    ))
}
