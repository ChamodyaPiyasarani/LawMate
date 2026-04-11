import SwiftUI

struct DocumentFile: Identifiable, Hashable {
    let id = UUID()
    let filename: String
    let fileType: DocType
    let date: String
    let size: String
    
    enum DocType {
        case pdf, docx, jpg
        
        var icon: String {
            switch self {
            case .pdf: return "doc.text.fill" // Or better PDF icon if available
            case .docx: return "doc.fill"
            case .jpg: return "photo.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .pdf: return .red
            case .docx: return .blue
            case .jpg: return .orange
            }
        }
    }
}

struct DocumentsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let mockDocuments = [
        DocumentFile(filename: "Mediation Agreement.pdf", fileType: .pdf, date: "OCT 24", size: "2.4 MB"),
        DocumentFile(filename: "Financial_Statement_Final.docx", fileType: .docx, date: "OCT 20", size: "1.1 MB"),
        DocumentFile(filename: "Evidence_Photo_01.jpg", fileType: .jpg, date: "OCT 18", size: "4.5 MB")
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Green blob top-left
            GreenBlobBackground(style: .client)
                .frame(height: 300)
            
            VStack(spacing: 0) {
                // Header Custom Layout
                HStack(alignment: .top) {
                    LawMateBackButton(action: { dismiss() })
                    
                    Spacer()
                    
                    Text("Documents")
                        .font(.lmHeading)
                        .foregroundColor(.lmPrimary)
                        .padding(.top, 12)
                    
                    Spacer()
                    
                    CameraButton(action: {})
                        .padding(.top, 10)
                }
                .padding(.horizontal, 24)
                .padding(.top, 64)
                .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(mockDocuments) { doc in
                            DocumentCard(document: doc)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 120) // Bottom nav padding
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct DocumentCard: View {
    let document: DocumentFile
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon container
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(document.fileType.color.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: document.fileType.icon)
                    .font(.system(size: 20))
                    .foregroundColor(document.fileType.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(document.filename)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lmPrimary)
                    .lineLimit(1)
                
                Text("\(document.date) • \(document.size)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.lmTextSecondary)
                    .textCase(.uppercase)
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.white.opacity(0.8))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    DocumentsView()
}
