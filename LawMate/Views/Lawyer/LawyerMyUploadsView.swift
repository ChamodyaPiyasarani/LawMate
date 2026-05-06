import SwiftUI

struct LawyerMyUploadsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firestore = FirestoreManager.shared
    
    @State private var showDeleteAlert = false
    @State private var documentToDelete: FBAdvisoryDocument? = nil
    @State private var showPDFViewer = false
    @State private var selectedDocument: FBAdvisoryDocument? = nil
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Lawyer Style Blob
            GreenBlobBackground(style: .lawyer)
                .frame(height: 300)
            
            VStack(spacing: 0) {
                // Header
                LawMateNavigationBar(
                    title: "My Documents",
                    showBack: true,
                    onBack: { dismiss() }
                )
                .padding(.top, 54)
                .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Manage your published advisory documents")
                            .font(.lmBody)
                            .foregroundColor(.lmTextSecondary)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                        
                        // Documents list
                        let myDocs = firestore.advisoryDocuments.filter { $0.lawyerId == AuthService.shared.currentUser?.id }
                        VStack(spacing: 16) {
                            if myDocs.isEmpty {
                                emptyState
                            } else {
                                ForEach(myDocs) { doc in
                                    documentRow(for: doc)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 16)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
        .alert("Remove Document", isPresented: $showDeleteAlert, presenting: documentToDelete) { doc in
            Button("Delete", role: .destructive) {
                withAnimation {
                    if let docId = doc.id {
                        firestore.deleteAdvisoryDocument(id: docId)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { doc in
            Text("Are you sure you want to permanently remove '\(doc.title)'? This will remove it from the public view.")
        }
        .sheet(isPresented: $showPDFViewer) {
            if let doc = selectedDocument {
                PDFKitViewerSheet(document: doc)
            }
        }
    }
    
    private func documentRow(for doc: FBAdvisoryDocument) -> some View {
        Button {
            self.selectedDocument = doc
            self.showPDFViewer = true
        } label: {
            HStack(spacing: 16) {
                // File Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.lmPrimary.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.lmPrimary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(doc.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.lmPrimary)
                        .lineLimit(1)
                    
                    Text("\(doc.category) • \(doc.date)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.lmTextSecondary)
                }
                
                Spacer()
                
                // Visibility Toggle & Delete
                HStack(spacing: 12) {
                    Menu {
                        Button {
                            if let id = doc.id {
                                firestore.updateAdvisoryDocumentVisibility(id: id, visibility: "Public")
                            }
                        } label: {
                            Label("Make Public", systemImage: "globe")
                        }
                        
                        Button {
                            if let id = doc.id {
                                firestore.updateAdvisoryDocumentVisibility(id: id, visibility: "Private")
                            }
                        } label: {
                            Label("Make Private", systemImage: "lock.fill")
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: doc.visibility == "Public" ? "globe" : "lock.fill")
                                .font(.system(size: 9))
                            Text(doc.visibility)
                                .font(.system(size: 10, weight: .bold))
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(doc.visibility == "Public" ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                        .foregroundColor(doc.visibility == "Public" ? .green : .orange)
                        .clipShape(Capsule())
                    }
                    
                    // Delete button
                    Button {
                        documentToDelete = doc
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red.opacity(0.8))
                            .frame(width: 36, height: 36)
                            .background(Color.red.opacity(0.05))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.6))
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.lmPrimary.opacity(0.3))
            
            Text("No documents published")
                .font(.lmHeading)
                .foregroundColor(.lmPrimary.opacity(0.6))
            
            Text("You can upload new advisory documents from the home dashboard.")
                .font(.lmCaption)
                .foregroundColor(.lmTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 64)
    }
}

#Preview {
    LawyerMyUploadsView()
}
