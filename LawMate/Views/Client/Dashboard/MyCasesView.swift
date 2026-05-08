import SwiftUI

struct ClientCase: Identifiable, Hashable {
    let id: String
    let lawyerName: String
    let description: String
    let category: String
    let method: String?
    let statusTitle: String
    let statusColorCategory: String // Helper to determine colors
    
    // Conform to Hashable for navigation
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: ClientCase, rhs: ClientCase) -> Bool { lhs.id == rhs.id }
}

struct MyCasesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firestore: FirestoreManager
    @State private var editingCase: FBLegalCase? = nil
    @State private var showEditSheet = false
    @Binding var navPath: NavigationPath
    @Binding var activeConversation: FBConversation?
    
    // Filter State
    @State private var searchText = ""
    @State private var selectedStatus = "All"
    
    private let statusFilters = ["All", "Active", "Pending", "Closed"]
    
    var filteredCases: [FBLegalCase] {
        firestore.cases.filter { clientCase in
            let matchesSearch = searchText.isEmpty || 
                               clientCase.title.localizedCaseInsensitiveContains(searchText) ||
                               clientCase.lawyerName.localizedCaseInsensitiveContains(searchText) ||
                               clientCase.caseNumber.localizedCaseInsensitiveContains(searchText)
            
            let matchesStatus = selectedStatus == "All" || 
                               clientCase.status.lowercased() == selectedStatus.lowercased() ||
                               (selectedStatus == "Active" && (clientCase.status.lowercased() == "confirmed" || clientCase.status.lowercased() == "in progress")) ||
                               (selectedStatus == "Pending" && clientCase.status.lowercased() == "pending") ||
                               (selectedStatus == "Closed" && clientCase.status.lowercased() == "closed")
            
            return matchesSearch && matchesStatus
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Green blob top-left
            GreenBlobBackground(style: .client)
                .frame(height: 300)
            
            VStack(spacing: 0) {
                // MARK: Left-Aligned Header
                HStack(alignment: .center) {
                    LawMateBackButton(action: { dismiss() })
                        .padding(.trailing, 8)
                        
                    Text("My Cases")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    Spacer()
                    
                    NotificationButton()
                        .padding(6)
                        .background(Circle().fill(Color.white.opacity(0.9)))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.top, 65)
                .padding(.bottom, 20)
                .zIndex(10)
                
                // MARK: Search & Filters
                VStack(spacing: 16) {
                    LawMateSearchBar(text: $searchText, placeholder: "Search by title, lawyer or case #")
                        .padding(.horizontal, 24)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(statusFilters, id: \.self) { status in
                                FilterChip(title: status, isSelected: selectedStatus == status) {
                                    withAnimation(.spring()) {
                                        selectedStatus = status
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if filteredCases.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundColor(.lmPrimary.opacity(0.2))
                                Text("No cases found")
                                    .font(.custom("Outfit-Medium", size: 16))
                                    .foregroundColor(.lmTextSecondary)
                                if !searchText.isEmpty {
                                    Text("Try adjusting your search or filters")
                                        .font(.system(size: 14))
                                        .foregroundColor(.lmTextSecondary.opacity(0.6))
                                }
                            }
                            .padding(.top, 100)
                        } else {
                            ForEach(filteredCases) { clientCase in
                                NavigationLink(value: clientCase) {
                                    MyCaseCard(clientCase: clientCase, onDelete: {
                                        firestore.deleteCase(id: clientCase.id ?? "")
                                    }, onEdit: {
                                        editingCase = clientCase
                                        showEditSheet = true
                                    })
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                    .padding(.bottom, 140) // Give space for bottom nav
                }
            }
            
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showEditSheet) {
            if let ec = editingCase {
                NavigationStack {
                    AddCaseView(editingCase: ec)
                }
            }
        }

        .onAppear {
            if let currentUser = AuthService.shared.currentUser {
                firestore.listenForCases(role: currentUser.role, userId: currentUser.id)
            }
        }
    }
}

// MARK: - Case Card Component
struct MyCaseCard: View {
    let clientCase: FBLegalCase
    let onDelete: () -> Void
    let onEdit: () -> Void
    @State private var showDeleteAlert = false
    
    var statusColor: Color {
        switch clientCase.status {
        case "Active", "Confirmed": return .green
        case "Pending", "In Progress": return .orange
        case "Closed": return .gray
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                LawMateAvatar(url: clientCase.lawyerImage, name: clientCase.lawyerName, size: 56)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text(clientCase.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.lmPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                        
                        // Status Badge
                        Text(clientCase.status)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    Text(clientCase.lawyerName.isEmpty ? "Assigned Lawyer" : clientCase.lawyerName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.lmPrimary.opacity(0.6))
                        .lineLimit(1)
                }
            }
            
            HStack {
                Text(clientCase.type)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.lmPrimary.opacity(0.7))
                
                Spacer()
                
                Text(clientCase.caseNumber)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.lmPrimary.opacity(0.7))
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.6))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit Case", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: {
                showDeleteAlert = true
            }) {
                Label("Delete Case", systemImage: "trash")
            }
        }
        .alert("Delete Case", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this case? This action cannot be undone.")
        }
    }
}

#Preview {
    MyCasesView(navPath: .constant(NavigationPath()), activeConversation: .constant(nil))
}
