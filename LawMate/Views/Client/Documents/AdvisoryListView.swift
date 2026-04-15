import SwiftUI

struct AdvisoryListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var showFilterSheet = false
    
    // MARK: - Mock Data
    @State private var allDocuments: [AdvisoryDocument] = [
        AdvisoryDocument(
            title: "Divorce Proceedings Guide 2024",
            description: "A comprehensive guide explaining the step-by-step legal procedure for filing for divorce in Sri Lanka.",
            category: "Family Law",
            tags: ["divorce", "custody", "legal-aid"],
            lawyerName: "Atty. Nimal Perera",
            date: "Apr 10, 2026",
            fileType: "PDF"
        ),
        AdvisoryDocument(
            title: "Commercial Lease Agreement Template",
            description: "Standard commercial lease agreement including clauses for security deposit and maintenance responsibilities.",
            category: "Property Law",
            tags: ["lease", "rent", "commercial"],
            lawyerName: "Atty. Sarah De Silva",
            date: "Apr 11, 2026",
            fileType: "DOCX"
        ),
        AdvisoryDocument(
            title: "Criminal Defense Rights",
            description: "An overview of person's fundamental rights when being questioned or detained by authorities.",
            category: "Criminal Law",
            tags: ["rights", "defense", "detention"],
            lawyerName: "Atty. Kasun Rajapakshe",
            date: "Apr 08, 2026",
            fileType: "PDF"
        ),
        AdvisoryDocument(
            title: "Intellectual Property Basics",
            description: "Understanding trademarks, copyrights and patents for small business owners and content creators.",
            category: "Corporate Law",
            tags: ["IP", "trademark", "business"],
            lawyerName: "Atty. Sarah De Silva",
            date: "Apr 05, 2026",
            fileType: "PDF"
        )
    ]
    
    private let categories = ["All", "Family Law", "Criminal Law", "Property Law", "Corporate Law"]

    var filteredDocuments: [AdvisoryDocument] {
        allDocuments.filter { doc in
            let matchesCategory = selectedCategory == "All" || doc.category == selectedCategory
            let matchesSearch = searchText.isEmpty || 
                               doc.title.localizedCaseInsensitiveContains(searchText) ||
                               doc.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) }) ||
                               doc.category.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
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
                        .padding(.top, 12)
                    
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
                    .padding(.top, 10)
                }
                .padding(.horizontal, 24)
                .padding(.top, 64)
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
                                    NavigationLink(value: doc) {
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
            FilterBottomSheet(selectedCategory: $selectedCategory, categories: categories)
                .presentationDetents([.medium])
        }
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

struct AdvisoryDocumentCard: View {
    let document: AdvisoryDocument
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 52, height: 52)
                    Image(systemName: iconName)
                        .font(.system(size: 24))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.lmPrimary)
                        .lineLimit(1)
                    
                    Text(document.description)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.lmTextSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lmPrimary.opacity(0.3))
            }
            
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: categoryIcon(for: document.category))
                        .font(.system(size: 10))
                    Text(document.category)
                        .font(.system(size: 10, weight: .bold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.lmPrimary.opacity(0.1))
                .foregroundColor(.lmPrimary)
                .clipShape(Capsule())
                
                ForEach(document.tags.prefix(2), id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.lmTextSecondary)
                }
                
                Spacer()
                
                Text(document.lawyerName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.lmPrimary.opacity(0.6))
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.8))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
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
    let categories: [String]
    
    var body: some View {
        VStack(spacing: 32) {
            HStack {
                Text("Filters")
                    .font(.lmHeading)
                Spacer()
                Button("Clear All") {
                    selectedCategory = "All"
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
                        FilterChip(title: "PDF", isSelected: true)
                        FilterChip(title: "DOCX", isSelected: false)
                        FilterChip(title: "Image", isSelected: false)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sort By").font(.system(size: 14, weight: .bold))
                    HStack {
                        FilterChip(title: "Latest", isSelected: true)
                        FilterChip(title: "Oldest", isSelected: false)
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

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.lmPrimary : Color.white)
            .foregroundColor(isSelected ? .white : .lmPrimary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.lmPrimary.opacity(0.2), lineWidth: 1))
    }
}

#Preview {
    AdvisoryListView()
}
