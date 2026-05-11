import SwiftUI

struct AdvisoryListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var selectedFileType = "All"
    @State private var selectedSort = "Latest"
    @State private var showFilterSheet = false
    @State private var selectedDocumentForDetail: FBAdvisoryDocument? = nil
    
    @EnvironmentObject var firestore: FirestoreManager
    
    private let categories = ["All", "Family Law", "Criminal Law", "Property Law", "Corporate Law"]

    var filteredDocuments: [FBAdvisoryDocument] {
        let filtered = firestore.advisoryDocuments.filter { doc in
            // Must be Public for clients
            guard doc.visibility == "Public" else { return false }
            
            let matchesCategory = selectedCategory == "All" || doc.category == selectedCategory
            let matchesFileType = matchesSelectedFileType(doc)
            let matchesSearch = searchText.isEmpty || 
                               doc.title.localizedCaseInsensitiveContains(searchText) ||
                               doc.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) }) ||
                               doc.category.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesFileType && matchesSearch
        }
        return sortDocuments(filtered)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Background Blob
            GreenBlobBackground(style: .client)
                .frame(height: 350)
                .offset(y: -50)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    LawMateBackButton(action: { dismiss() })
                    
                    Spacer()
                    
                    Text("Advisory Documents")
                        .font(.lmHeading)
                        .foregroundColor(.lmPrimary)
                    
                    Spacer()
                    
                    Button {
                        showFilterSheet = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.lmPrimary)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 65)
                .zIndex(10)
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Standardized Search Bar
                        LawMateSearchBar(text: $searchText, placeholder: "Search title, tags, or category")
                            .padding(.horizontal, 24)
                            .padding(.top, 30)
                        
                        // Document List
                        VStack(spacing: 20) {
                            if filteredDocuments.isEmpty {
                                emptyState
                            } else {
                                ForEach(filteredDocuments) { doc in
                                    Button {
                                        selectedDocumentForDetail = doc
                                    } label: {
                                        AdvisoryDocumentCard(document: doc)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Color.clear.frame(height: 120)
                    }
                }
            }
        }
        
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showFilterSheet) {
            FilterBottomSheet(
                selectedCategory: $selectedCategory,
                selectedFileType: $selectedFileType,
                selectedSort: $selectedSort,
                categories: categories
            )
                .presentationDetents([.medium])
        }
        .sheet(item: $selectedDocumentForDetail) { doc in
            DocumentDetailView(document: doc)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func matchesSelectedFileType(_ doc: FBAdvisoryDocument) -> Bool {
        if selectedFileType == "All" { return true }
        let fileType = doc.fileType.uppercased()
        switch selectedFileType {
        case "PDF":
            return fileType == "PDF"
        case "DOCX":
            return fileType == "DOCX" || fileType == "DOC"
        case "Image":
            return fileType == "JPG" || fileType == "JPEG" || fileType == "PNG" || fileType == "IMAGE"
        default:
            return true
        }
    }

    private func sortDocuments(_ docs: [FBAdvisoryDocument]) -> [FBAdvisoryDocument] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        let sorted = docs.sorted { lhs, rhs in
            let leftDate = formatter.date(from: lhs.date) ?? Date.distantPast
            let rightDate = formatter.date(from: rhs.date) ?? Date.distantPast
            return leftDate > rightDate
        }
        if selectedSort == "Oldest" {
            return sorted.reversed()
        }
        return sorted
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.lmPrimary.opacity(0.2))
            Text("No documents found")
                .font(.lmHeading)
                .foregroundColor(.lmPrimary.opacity(0.6))
            Text("Try adjusting your filters or search query")
                .font(.lmCaption)
                .foregroundColor(.lmTextSecondary)
        }
        .padding(.vertical, 64)
    }
}

// MARK: - Supporting Views

// MARK: - Supporting Views

struct AdvisoryDocumentCard: View {
    let document: FBAdvisoryDocument
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Section
            HStack(alignment: .top, spacing: 16) {
                // Initial/Icon Box
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 24))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        Text(document.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.05, green: 0.25, blue: 0.22)) // Dark greenish
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.lmPrimary.opacity(0.3))
                    }
                    
                    Text(document.description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.lmTextSecondary)
                        .lineLimit(2)
                }
            }
            .padding(.bottom, 20)
            
            Divider()
                .background(Color.lmPrimary.opacity(0.05))
                .padding(.bottom, 16)
            
            // Footer Section
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: categoryIcon(for: document.category))
                        .font(.system(size: 12))
                    Text(document.category)
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(Color(red: 0.35, green: 0.45, blue: 0.42))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.lmPrimary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 10))
                    Text(document.lawyerName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.lmTextSecondary.opacity(0.8))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.lmTextSecondary.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Family Law": return "person.2.fill"
        case "Criminal Law": return "shield.fill"
        case "Property Law": return "house.fill"
        case "Corporate Law": return "briefcase.fill"
        default: return "grid.fill"
        }
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

struct FilterBottomSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: String
    @Binding var selectedFileType: String
    @Binding var selectedSort: String
    let categories: [String]
    
    var body: some View {
        VStack(spacing: 32) {
            HStack {
                Text("Filters")
                    .font(.lmHeading)
                Spacer()
                Button("Clear All") {
                    selectedCategory = "All"
                    selectedFileType = "All"
                    selectedSort = "Latest"
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.red)
            }
            
            VStack(alignment: .leading, spacing: 20) {
                // Category Dropdown (Menu)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Legal Category").font(.system(size: 14, weight: .bold))
                    
                    Menu {
                        ForEach(categories, id: \.self) { cat in
                            Button {
                                selectedCategory = cat
                            } label: {
                                HStack {
                                    Text(cat)
                                    if selectedCategory == cat {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedCategory)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.lmPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.lmPrimary.opacity(0.5))
                        }
                        .padding()
                        .background(Color.white.opacity(0.5))
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lmPrimary.opacity(0.1), lineWidth: 1))
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("File Type").font(.system(size: 14, weight: .bold))
                    HStack {
                        FilterChip(title: "All", isSelected: selectedFileType == "All") {
                            selectedFileType = "All"
                        }
                        FilterChip(title: "PDF", isSelected: selectedFileType == "PDF") {
                            selectedFileType = "PDF"
                        }
                        FilterChip(title: "DOCX", isSelected: selectedFileType == "DOCX") {
                            selectedFileType = "DOCX"
                        }
                        FilterChip(title: "Image", isSelected: selectedFileType == "Image") {
                            selectedFileType = "Image"
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sort By").font(.system(size: 14, weight: .bold))
                    HStack {
                        FilterChip(title: "Latest", isSelected: selectedSort == "Latest") {
                            selectedSort = "Latest"
                        }
                        FilterChip(title: "Oldest", isSelected: selectedSort == "Oldest") {
                            selectedSort = "Oldest"
                        }
                    }
                }
            }
            
            Spacer()
            
            LawMatePrimaryButton(title: "Apply Filters") {
                dismiss()
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
        .padding(.top, 44)
        .background(Color.lmBackground)
    }
}

#Preview {
    AdvisoryListView()
}
