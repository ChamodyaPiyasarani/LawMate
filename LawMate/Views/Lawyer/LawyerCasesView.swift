import SwiftUI

struct LawyerCasesView: View {
    @State private var searchText: String = ""
    @State private var selectedStatus: String? = nil
    
    // Statuses for filtering
    let statuses = ["Active", "Pending", "Closed"]
    
    // Mock cases using the new model
    let cases = [
        LegalCase.mockCase,
        LegalCase(
            id: "2",
            caseNumber: "CLM-2024-005",
            title: "Property Transfer Agreement",
            clientName: "Amara Silva",
            type: "Property Law",
            status: "Pending",
            priority: "Medium",
            lawyerName: "Atty. John Doe",
            createdDate: Date().addingTimeInterval(-86400 * 10),
            stages: LegalCase.mockStages,
            documents: []
        ),
        LegalCase(
            id: "3",
            caseNumber: "CLM-2024-012",
            title: "Corporate Contract Review",
            clientName: "Kamal de Silva",
            type: "Corporate Law",
            status: "Closed",
            priority: "Low",
            lawyerName: "Atty. John Doe",
            createdDate: Date().addingTimeInterval(-86400 * 30),
            stages: LegalCase.mockStages,
            documents: LegalCase.mockDocs
        )
    ]
    
    var filteredCases: [LegalCase] {
        cases.filter { c in
            let matchesSearch = searchText.isEmpty || c.clientName.lowercased().contains(searchText.lowercased()) || c.title.lowercased().contains(searchText.lowercased())
            let matchesStatus = selectedStatus == nil || c.status == selectedStatus
            return matchesSearch && matchesStatus
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.lmBackground.ignoresSafeArea()
                
                // Flipped Green blob (Lawyer Style)
                GreenBlobBackground(style: .lawyer)
                    .frame(height: 350)
                    .offset(y: -50)
                
                VStack(spacing: 0) {
                    // MARK: Left-Aligned Header
                    HStack(alignment: .center) {
                        Text("My Cases")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.lmPrimary)
                        
                        Spacer()
                        
                        NotificationButton(badgeCount: 3, action: {})
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 64)
                    .padding(.bottom, 24)
                    
                    // MARK: Search Section
                    VStack(spacing: 20) {
                        LawMateSearchBar(text: $searchText, placeholder: "Search cases or clients...")
                            .padding(.horizontal, 24)
                        
                        // Status Filters
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(statuses, id: \.self) { status in
                                    FilterPill(
                                        icon: statusIcon(for: status),
                                        title: status,
                                        isActive: selectedStatus == status,
                                        action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                if selectedStatus == status {
                                                    selectedStatus = nil
                                                } else {
                                                    selectedStatus = status
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 16)
                    
                    // MARK: Case List
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            ForEach(filteredCases) { lawyerCase in
                                NavigationLink {
                                    LawyerCaseDetailView(legalCase: lawyerCase)
                                } label: {
                                    LawyerCaseCard(lawyerCase: lawyerCase)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                        .padding(.bottom, 150)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
    }
    
    private func statusIcon(for status: String) -> String {
        switch status {
        case "Active": return "clock.fill"
        case "Pending":  return "hourglass"
        case "Closed":   return "checkmark.circle.fill"
        default: return "doc.text"
        }
    }
}

// MARK: - Lawyer Case Card
struct LawyerCaseCard: View {
    let lawyerCase: LegalCase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                // Client Avatar
                ZStack {
                    Circle()
                        .fill(Color.lmPrimary.opacity(0.1))
                        .frame(width: 64, height: 64)
                    Image(systemName: "person.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.lmPrimary.opacity(0.3))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        Text(lawyerCase.clientName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.lmPrimary)
                        
                        Spacer()
                        
                        // Status Badge
                        Text(lawyerCase.status)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    Text(lawyerCase.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.lmPrimary.opacity(0.8))
                    
                    Text(lawyerCase.caseNumber)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.lmTextSecondary)
                }
            }
            
            HStack {
                Text(lawyerCase.type)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.lmPrimary.opacity(0.7))
                
                Spacer()
                
                Text(priorityText)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(priorityColor)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.6))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    private var statusColor: Color {
        switch lawyerCase.status {
        case "Active": return .orange
        case "Closed": return .gray
        case "Pending": return .blue
        default: return .lmPrimary
        }
    }
    
    private var priorityColor: Color {
        switch lawyerCase.priority.lowercased() {
        case "high": return .red
        case "medium": return .orange
        case "low": return .green
        default: return .lmPrimary
        }
    }
    
    private var priorityText: String {
        "\(lawyerCase.priority) Priority"
    }
}

#Preview {
    NavigationStack {
        LawyerCasesView()
    }
}

import UniformTypeIdentifiers

// MARK: - Lawyer Case Detail View
struct LawyerCaseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var legalCase: LegalCase
    
    @State private var selectedTab = 0 // 0: Progress, 1: Documents
    @State private var showFilePicker = false
    @State private var selectedStageIndex: Int? = nil
    
    init(legalCase: LegalCase) {
        _legalCase = State(initialValue: legalCase)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Flipped Green blob (Lawyer Style)
            GreenBlobBackground(style: .lawyer)
                .frame(height: 350)
                .offset(y: -50)
            
            VStack(spacing: 0) {
                // MARK: Custom Header
                LawMateNavigationBar(
                    title: "Case Details",
                    showBack: true,
                    onBack: { dismiss() }
                )
                .padding(.top, 64)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // MARK: Case Profile Header Card
                        caseProfileHeader
                        
                        // MARK: Tab Selector
                        tabSelector
                        
                        // MARK: Tab Content
                        if selectedTab == 0 {
                            progressTab
                        } else {
                            documentsTab
                        }
                        
                        Color.clear.frame(height: 100)
                    }
                    .padding(24)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            if let index = selectedStageIndex {
                handleFileUpload(result: result, stageIndex: index)
            }
        }
    }
    
    // MARK: - Logic
    
    private func toggleStageCompletion(at index: Int) {
        withAnimation(.spring()) {
            legalCase.stages[index].isCompleted.toggle()
            if legalCase.stages[index].isCompleted {
                legalCase.stages[index].date = Date()
            } else {
                legalCase.stages[index].date = nil
            }
            
            // Update overall status if everything is done
            if legalCase.stages.allSatisfy({ $0.isCompleted }) {
                legalCase.status = "Closed"
            } else if legalCase.stages.anySatisfy({ $0.isCompleted }) {
                legalCase.status = "Active"
            }
        }
    }
    
    private func handleFileUpload(result: Result<[URL], Error>, stageIndex: Int) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Mock adding a document
            let newDoc = LegalCaseDocument(
                fileName: url.lastPathComponent,
                fileType: url.pathExtension.uppercased(),
                uploadedAt: Date(),
                uploadedStage: legalCase.stages[stageIndex].title
            )
            
            withAnimation(.spring()) {
                legalCase.documents.append(newDoc)
            }
            
        case .failure(let error):
            print("File selection error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Subviews
    
    private var caseProfileHeader: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                // Client Avatar
                ZStack {
                    Circle()
                        .fill(Color.lmPrimary.opacity(0.1))
                        .frame(width: 72, height: 72)
                    Image(systemName: "person.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.lmPrimary.opacity(0.3))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(legalCase.caseNumber)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.lmPrimary)
                        
                        Spacer()
                        
                        // Priority Badge
                        Text(legalCase.priority)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(priorityColor)
                            .clipShape(Capsule())
                    }
                    
                    Text(legalCase.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.lmPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(legalCase.clientName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.lmTextSecondary)
                }
            }
            
            Divider()
                .background(Color.lmPrimary.opacity(0.1))
            
            // Case Stats (Progress Summary)
            HStack(spacing: 30) {
                statItem(title: "Status", value: legalCase.status, icon: "clock.badge.checkmark", color: .orange)
                statItem(title: "Progress", value: "\(Int(legalCase.progressProgress * 100))%", icon: "chart.bar.fill", color: .lmPrimary)
                statItem(title: "Files", value: "\(legalCase.documents.count)", icon: "doc.fill", color: .blue)
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.6))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.5), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton(title: "Progress", index: 0, icon: "checklist")
            tabButton(title: "Documents", index: 1, icon: "folder.fill")
        }
        .padding(6)
        .background(Color.white.opacity(0.4))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
    }
    
    private func tabButton(title: String, index: Int, icon: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(selectedTab == index ? .white : .lmPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(selectedTab == index ? Color.lmPrimary : Color.clear)
            .clipShape(Capsule())
        }
    }
    
    // MARK: - Tab Views
    
    private var progressTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Case Lifecycle")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.lmPrimary)
                .padding(.bottom, 24)
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<legalCase.stages.count, id: \.self) { index in
                    let stage = legalCase.stages[index]
                    let isActive = !stage.isCompleted && (index == 0 || legalCase.stages[index-1].isCompleted)
                    
                    TimelineNode(
                        index: index,
                        stage: stage,
                        isLast: index == legalCase.stages.count - 1,
                        isActive: isActive,
                        canEdit: true,
                        onToggle: { toggleStageCompletion(at: index) },
                        onUpload: {
                            selectedStageIndex = index
                            showFilePicker = true
                        }
                    )
                }
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.4))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.3), lineWidth: 1))
    }
    
    private var documentsTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Case Documents")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.lmPrimary)
                
                Spacer()
                
                Text("\(legalCase.documents.count) Files")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.lmTextSecondary)
            }
            
            if legalCase.documents.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.lmPrimary.opacity(0.2))
                    Text("No documents uploaded yet.")
                        .font(.system(size: 14))
                        .foregroundColor(.lmTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(legalCase.documents) { doc in
                    caseDocumentRow(doc)
                }
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.4))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.3), lineWidth: 1))
    }
    
    // MARK: - Helper Components
    
    private func statItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.lmTextSecondary)
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lmPrimary)
            }
        }
    }
    
    private func caseDocumentRow(_ doc: LegalCaseDocument) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.lmPrimary.opacity(0.1))
                    .frame(width: 48, height: 48)
                Image(systemName: doc.iconName)
                    .foregroundColor(.lmPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(doc.fileName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.lmPrimary)
                
                HStack(spacing: 8) {
                    Text(doc.uploadedStage)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.lmPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.lmPrimary.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Text(formatDate(doc.uploadedAt))
                        .font(.system(size: 11))
                        .foregroundColor(.lmTextSecondary)
                }
            }
            
            Spacer()
            
            Button {
                // View action
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lmPrimary.opacity(0.5))
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: date)
    }
    
    private var priorityColor: Color {
        switch legalCase.priority.lowercased() {
        case "high": return .red
        case "medium": return .orange
        case "low": return .green
        default: return .lmPrimary
        }
    }
}

extension Array {
    func anySatisfy(_ predicate: (Element) -> Bool) -> Bool {
        return self.contains(where: predicate)
    }
}
