import SwiftUI

struct LawyerCasesView: View {
    @State private var searchText: String = ""
    @State private var selectedStatus: String? = nil
    
    // Statuses for filtering
    let statuses = ["Active", "Pending", "Closed"]
    
    @StateObject private var firestore = FirestoreManager.shared
    @State private var showNotifications = false
    
    var filteredCases: [FBLegalCase] {
        firestore.cases.filter { c in
            let title = c.title 
            let client = c.clientName 
            let matchesSearch = searchText.isEmpty || client.lowercased().contains(searchText.lowercased()) || title.lowercased().contains(searchText.lowercased())
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
                        
                        NotificationButton(action: {
                            showNotifications = true
                        })
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
            .onAppear {
                if let currentUser = AuthService.shared.currentUser {
                    firestore.listenForCases(role: currentUser.role, userId: currentUser.id)
                }
            }
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsView()
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
    let lawyerCase: FBLegalCase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                LawMateAvatar(url: lawyerCase.clientImage, name: lawyerCase.clientName, size: 64)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        Text(lawyerCase.clientName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.lmPrimary)
                            .lineLimit(1)
                            .layoutPriority(1)
                        
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
                        .lineLimit(1)
                    
                    Text(lawyerCase.caseNumber)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.lmTextSecondary)
                        .lineLimit(1)
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
    
    var legalCase: FBLegalCase
    
    @State private var selectedTab = 0 // 0: Progress, 1: Documents
    @State private var showFilePicker = false
    @State private var selectedStageIndex: Int? = nil
    @State private var selectedDocument: FBDocument? = nil
    
    init(legalCase: FBLegalCase) {
        self.legalCase = legalCase
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
        .sheet(item: $selectedDocument) { doc in
            let dummyDoc = FBAdvisoryDocument(
                id: doc.id ?? UUID().uuidString,
                title: doc.fileName,
                description: "",
                category: "Case Document",
                tags: [],
                lawyerName: "",
                date: ISO8601DateFormatter().string(from: doc.uploadedAt),
                fileType: doc.fileType,
                fileURL: doc.fileURL,
                lawyerId: "",
                visibility: "Private"
            )
            PDFKitViewerSheet(document: dummyDoc)
        }
    }
    
    // MARK: - Logic
    
    private func toggleStageCompletion(at index: Int) {
        var updatedCase = legalCase
        updatedCase.stages[index].isCompleted.toggle()
        if updatedCase.stages[index].isCompleted {
            updatedCase.stages[index].date = Date()
        } else {
            updatedCase.stages[index].date = nil
        }
        
        // Update status logic
        if updatedCase.stages.allSatisfy({ $0.isCompleted }) {
            updatedCase.status = "Closed"
        } else if updatedCase.stages.contains(where: { $0.isCompleted }) {
            updatedCase.status = "Active"
        }
        
        FirestoreManager.shared.updateCase(updatedCase)
    }
    
    private func handleFileUpload(result: Result<[URL], Error>, stageIndex: Int) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Start security access
            let started = url.startAccessingSecurityScopedResource()
            defer { if started { url.stopAccessingSecurityScopedResource() } }
            
            do {
                let data = try Data(contentsOf: url)
                let originalName = url.lastPathComponent
                let safeStorageName = UUID().uuidString + "." + url.pathExtension
                let fileType = url.pathExtension.uppercased()
                let path = "cases/\(legalCase.id ?? "unknown")/docs"
                
                ToastManager.shared.show(title: "Uploading", message: "Starting file upload...", type: .info)
                
                FirestoreManager.shared.uploadFile(data: data, path: path, fileName: safeStorageName) { uploadResult in
                    switch uploadResult {
                    case .success(let downloadURL):
                        // Track the metadata in Firestore with the actual URL
                        FirestoreManager.shared.addDocument(
                            toCaseId: legalCase.id ?? "",
                            fileName: originalName,
                            fileType: fileType,
                            fileURL: downloadURL,
                            stageIndex: stageIndex
                        )
                        
                        // Update the stage to indicate a file was uploaded
                        var updatedCase = legalCase
                        updatedCase.stages[stageIndex].description += " (File attached)"
                        FirestoreManager.shared.updateCase(updatedCase)
                        
                        ToastManager.shared.show(title: "Success", message: "File uploaded successfully.", type: .success)
                        
                    case .failure(let error):
                        ToastManager.shared.show(title: "Upload Failed", message: error.localizedDescription, type: .error)
                    }
                }
            } catch {
                ToastManager.shared.show(title: "Access Error", message: "Could not read file data.", type: .error)
            }
            
        case .failure(let error):
            ToastManager.shared.show(title: "Error", message: error.localizedDescription, type: .error)
        }
    }
    
    // MARK: - Subviews
    
    private var caseProfileHeader: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                LawMateAvatar(url: legalCase.clientImage, name: legalCase.clientName, size: 72)
                
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
                statItem(title: "Files", value: "0", icon: "doc.fill", color: .blue) // Documents list migration handled separately
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
                
                Text("\(legalCase.wrappedDocuments.count) Files")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.lmTextSecondary)
            }
            
            if legalCase.wrappedDocuments.isEmpty {
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
                ForEach(legalCase.wrappedDocuments) { doc in
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
    
    private func caseDocumentRow(_ doc: FBDocument) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.lmPrimary.opacity(0.1))
                    .frame(width: 48, height: 48)
                Image(systemName: "doc.fill")
                    .foregroundColor(.lmPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(doc.fileName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.lmPrimary)
                
                HStack(spacing: 8) {
                    Text(doc.fileType)
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
                selectedDocument = doc
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
