import SwiftUI

// MARK: - Mock Models
struct CaseProgressStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let date: String
    let status: StepStatus
}

enum StepStatus {
    case completed, current, upcoming
}

struct ClientCaseDocument: Identifiable {
    let id = UUID()
    let title: String
    let type: String
    let dateAdded: String
}

// MARK: - Case Detail View (Progress & Documents)
struct CaseDetailView: View {
    let clientCase: FBLegalCase
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0 // 0: Progress, 1: Documents
    @State private var documents: [FBDocument] = []
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Green blob top-left
            GreenBlobBackground(style: .client)
                .frame(height: 300)
            
            VStack(spacing: 0) {
                // MARK: Custom Header
                LawMateNavigationBar(
                    title: "Case Overview",
                    showBack: true,
                    showNotification: true,
                    notificationCount: 0,
                    onBack: { dismiss() },
                    onNotification: {}
                )
                .padding(.top, 64)
                .zIndex(10)
                
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
                            .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))
                    } else {
                        documentsSection
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                    }
                    
                    Color.clear.frame(height: 120) // Bottom tab bar margin
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            FirestoreManager.shared.fetchDocuments(forCaseId: clientCase.id ?? "") { fetchedDocs in
                self.documents = fetchedDocs
            }
        }
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(clientCase.stages.enumerated()), id: \.offset) { index, stage in
                HStack(alignment: .top, spacing: 16) {
                    let isActive = !stage.isCompleted && (index == 0 || clientCase.stages[index-1].isCompleted)
                    let stepStatus: StepStatus = stage.isCompleted ? .completed : (isActive ? .current : .upcoming)
                    
                    // Timeline Graphics
                    VStack(spacing: 0) {
                        // Node
                        ZStack {
                            Circle()
                                .fill(stepStatus == .completed ? Color.lmPrimary : (stepStatus == .current ? Color.orange : Color.gray.opacity(0.3)))
                                .frame(width: 24, height: 24)
                            
                            if stepStatus == .completed {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            } else if stepStatus == .current {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        // Vertical Connecting Line
                        if index != clientCase.stages.count - 1 {
                            Rectangle()
                                .fill(stepStatus == .completed ? Color.lmPrimary : Color.gray.opacity(0.3))
                                .frame(width: 2)
                                .frame(minHeight: 50)
                        }
                    }
                    
                    // Step Content
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(stage.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(stepStatus == .upcoming ? .lmTextSecondary : .lmPrimary)
                            
                            Spacer()
                            
                            if let stepDate = stage.date {
                                Text("\(stepDate, style: .date)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.lmTextSecondary)
                            } else {
                                Text("TBD")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.lmTextSecondary)
                            }
                        }
                        
                        Text(stage.description)
                            .font(.system(size: 14))
                            .foregroundColor(.lmTextSecondary)
                            .padding(.bottom, 24)
                    }
                    .padding(.top, 2)
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
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.lmPrimary.opacity(0.1))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "doc.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.lmPrimary)
                            .overlay(
                                Text(doc.fileType)
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .background(Color.lmPrimary)
                                    .clipShape(Capsule())
                                    .offset(y: 10)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(doc.fileName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.lmPrimary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Text("Added \(doc.uploadedAt, style: .date)")
                            .font(.system(size: 12))
                            .foregroundColor(.lmTextSecondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        // View action
                    } label: {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.lmPrimary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(Color.white.opacity(0.8))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.03), radius: 5, y: 2)
            }
            
            if documents.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.lmPrimary.opacity(0.3))
                    Text("No documents yet")
                        .font(.lmBody)
                        .foregroundColor(.lmTextSecondary)
                }
                .padding(.top, 60)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
    }
}

// MARK: - Helper Tab Button
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isSelected ? .lmPrimary : .lmTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.white : Color.clear)
                .clipShape(Capsule())
                .shadow(color: isSelected ? Color.black.opacity(0.05) : .clear, radius: 4, y: 2)
        }
    }
}

// We omitted the static preview as it requires CoreData context mocking which is convoluted locally
