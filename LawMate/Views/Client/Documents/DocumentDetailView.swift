import SwiftUI

struct DocumentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPDFViewer = false
    let document: FBAdvisoryDocument
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Background Blob
            GreenBlobBackground(style: .client)
                .frame(height: 350)
                .offset(y: -50)
            
            VStack(spacing: 0) {
                // Header
                LawMateNavigationBar(
                    title: "Document Details",
                    showBack: true,
                    onBack: { dismiss() }
                )
                .padding(.top, 65)
                .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        // MARK: Main Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            // File Icon & Type
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(iconColor.opacity(0.1))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: iconName)
                                        .foregroundColor(iconColor)
                                }
                                
                                Text(document.fileType)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.lmTextSecondary)
                                
                                Spacer()
                                
                                // Category Badge
                                Text(document.category)
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.lmPrimary.opacity(0.1))
                                    .foregroundColor(.lmPrimary)
                                    .clipShape(Capsule())
                            }
                            
                            Text(document.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.lmPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            HStack(spacing: 20) {
                                metadataRow(icon: "person.fill", text: document.lawyerName)
                                metadataRow(icon: "calendar", text: document.date)
                            }
                        }
                        
                        // MARK: Tags
                        HStack(spacing: 8) {
                            ForEach(document.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.system(size: 13, weight: .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.5))
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                            }
                        }

                        // MARK: Description Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Description")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.lmPrimary)
                            
                            Text(document.description)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.lmTextSecondary)
                                .lineSpacing(6)
                        }
                        .padding(24)
                        .background(Color.white.opacity(0.4))
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.3), lineWidth: 1))

                        // MARK: Action Buttons
                        VStack(spacing: 16) {
                            LawMatePrimaryButton(title: "View Document") {
                                showPDFViewer = true
                            }
                            
                            HStack(spacing: 16) {
                                actionButton(icon: "square.and.arrow.down", title: "Download")
                                actionButton(icon: "square.and.arrow.up", title: "Share")
                            }
                        }
                        
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
        }
        
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showPDFViewer) {
            PDFKitViewerSheet(document: document)
        }
    }
    
    // MARK: - Subviews
    
    private func metadataRow(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.lmTextSecondary)
            Text(text)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.lmTextSecondary)
        }
    }
    
    private func actionButton(icon: String, title: String) -> some View {
        Button {
            // Action
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.lmPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.5))
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.lmPrimary.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
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
