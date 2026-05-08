import SwiftUI
import MapKit

struct ClientHomeView: View {
    @State private var selectedTab: LawMateTab = .home
    @State private var searchQuery: String = ""
    @State private var navPath = NavigationPath()
    @State private var activeConversation: FBConversation? = nil
    @State private var pendingChatId: String? = nil
    @AppStorage("biometricsEnabled") private var biometricsEnabled = false
    @State private var showBiometricOptIn = false
    @EnvironmentObject var firestore: FirestoreManager
    @EnvironmentObject var notifications: NotificationManager
    @EnvironmentObject var auth: AuthService
    @State private var isTabBarHidden = false
    
    // Simple routes for screens without complex data models
    enum AppRoute: Hashable {
        case myCases, documents, notifications, booking(Lawyer?), allAppointments, referrals
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.lmBackground.ignoresSafeArea()
            
            NavigationStack(path: $navPath) {
                VStack(spacing: 0) {
                    switch selectedTab {
                    case .home:
                        homeDashboard
                    case .lawyers:
                        LawyersListView(onBack: { selectedTab = .home }, isTabBarHidden: $isTabBarHidden, initialSearchQuery: searchQuery)
                    case .booking:
                        BookingDetailsView(navPath: $navPath, onBack: { selectedTab = .home })
                    case .messages:
                        MessagesListView(onBack: { selectedTab = .home }, onSelect: { conversation in
                            activeConversation = conversation
                        })
                    case .profile:
                        ProfileView(navPath: $navPath, activeConversation: $activeConversation, onBack: { selectedTab = .home })
                    case .cases:
                        MyCasesView(navPath: $navPath, activeConversation: $activeConversation)
                    case .calendar:
                        BookingDetailsView(navPath: $navPath)
                    }
                }
                .modifier(ClientHomeNavigationDestinations(navPath: $navPath, activeConversation: $activeConversation))
                .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
                .ignoresSafeArea(edges: .top)
                .onAppear {
                    if UserDefaults.standard.bool(forKey: "shouldShowBiometricPrompt") {
                        showBiometricOptIn = true
                    }
                }
                .alert("Enable Biometric Login?", isPresented: $showBiometricOptIn) {
                    Button("Yes, Enable") {
                        biometricsEnabled = true
                        UserDefaults.standard.set(false, forKey: "shouldShowBiometricPrompt")
                        ToastManager.shared.show(title: "Face ID Enabled", message: "You can now log in using biometrics.", type: .success)
                    }
                    Button("Not Now", role: .cancel) {
                        biometricsEnabled = false
                        KeychainManager.shared.clearCredentials()
                        UserDefaults.standard.set(false, forKey: "shouldShowBiometricPrompt")
                    }
                } message: {
                    Text("Would you like to use Face ID / Touch ID for faster login next time?")
                }
                .onChange(of: notifications.pendingRoute) { _, route in
                    guard let route = route else { return }
                    
                    // We no longer reset navPath = NavigationPath() here to avoid losing user work.
                    // Instead, we append the new route to the existing stack.
                    
                    switch route {
                    case .chat(let conversationId):
                        // If conversation is already loaded, open it immediately
                        if let conversation = firestore.conversations.first(where: { $0.id == conversationId }) {
                            activeConversation = conversation
                        } else {
                            // Otherwise, set pending ID and let the listener handle it
                            pendingChatId = conversationId
                            selectedTab = .messages
                        }
                    case .notificationCenter:
                        notifications.showNotifications = true
                    case .myCases:
                        // Move to the Home tab and append the Cases view to the stack
                        selectedTab = .home
                        navPath.append(AppRoute.myCases)
                    case .legalCase(let caseId):
                        if let legalCase = firestore.cases.first(where: { $0.id == caseId }) {
                            navPath.append(legalCase)
                        } else {
                            selectedTab = .home
                            navPath.append(AppRoute.myCases)
                        }
                    case .appointment(let appointmentId):
                        if let appointment = firestore.appointments.first(where: { $0.id == appointmentId }) {
                            navPath.append(appointment)
                        } else {
                            ToastManager.shared.show(title: "Appointment Unavailable", message: "This appointment has been cancelled or deleted.", type: .error)
                        }
                    case .lawyerProfile(let lawyerId):
                        if let user = firestore.lawyers.first(where: { $0.id == lawyerId }) {
                            let lawyer = Lawyer(
                                id: user.id,
                                name: user.fullName,
                                specialty: user.specialty ?? "General",
                                bio: user.bio ?? "",
                                description: user.bio ?? "",
                                experience: user.experience ?? "",
                                experienceYears: Int(user.experience?.components(separatedBy: " ").first ?? "0") ?? 0,
                                casesWon: user.casesWon ?? "0",
                                wonCount: Int(user.casesWon ?? "0") ?? 0,
                                rating: user.rating ?? 0.0,
                                reviewCount: user.reviewCount ?? 0,
                                location: user.address ?? "",
                                image: user.profileImage ?? "",
                                coordinate: CLLocationCoordinate2D(latitude: user.latitude ?? 0, longitude: user.longitude ?? 0)
                            )
                            navPath.append(lawyer)
                        } else {
                            ToastManager.shared.show(title: "Lawyer Unavailable", message: "The lawyer profile you're looking for is no longer available.", type: .error)
                        }
                    }
                    notifications.pendingRoute = nil
                }
                .toolbar(.hidden, for: .navigationBar)
            }

            // Persistent Tab Bar
            if activeConversation == nil && !isTabBarHidden {
                VStack {
                    Spacer()
                    TabBarView(selectedTab: $selectedTab, role: .client)
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $notifications.showNotifications) {
            NotificationsView(navPath: $navPath, activeConversation: $activeConversation)
                .presentationDetents([.large, .medium])
                .presentationDragIndicator(.visible)
        }
        .animation(.easeInOut(duration: 0.2), value: navPath.isEmpty && activeConversation == nil)
        .onChange(of: selectedTab) { _, _ in
            navPath = NavigationPath()
            activeConversation = nil
        }
        .onChange(of: firestore.conversations) { _, _ in
            tryNavigateToPendingChat()
        }
        .onAppear {
            if let user = auth.currentUser {
                firestore.startSync(role: user.role, userId: user.id)
            }
        }
    }

    private func tryNavigateToPendingChat() {
        guard let pendingChatId = pendingChatId else { return }
        if let conv = firestore.conversations.first(where: { $0.id == pendingChatId }) {
            activeConversation = conv
            self.pendingChatId = nil
        } else if !firestore.conversations.isEmpty {
            ToastManager.shared.show(title: "Chat Error", message: "We couldn't open that conversation. Please try again.", type: .error)
            self.pendingChatId = nil
        }
    }

    private var homeDashboard: some View {
        ScrollView(showsIndicators: false) {
            ZStack(alignment: .topTrailing) {
                GreenBlobBackground(style: .client)
                    .frame(height: 300)

                VStack(alignment: .leading, spacing: 28) {
                    dashboardHeader
                    
                    VStack(spacing: 24) {
                        // 1. Search Bar at the top
                        FindLawyerCard(searchQuery: $searchQuery, selectedTab: $selectedTab, navPath: $navPath)
                        
                        // 2. Upcoming Appointments
                        upcomingAppointmentsSection
                        
                        // 3. Case Progress
                        caseProgressSection
                        
                        // 4. Quick Actions
                        HStack(spacing: 12) {
                            ClientActionButton(icon: "doc.text.fill", title: "My Cases", color: .blue) {
                                navPath.append(AppRoute.myCases)
                            }
                            ClientActionButton(icon: "doc.on.doc.fill", title: "Documents", color: .orange) {
                                navPath.append(AppRoute.documents)
                            }
                            ClientActionButton(icon: "arrowshape.turn.up.right.fill", title: "Referrals", color: .purple) {
                                navPath.append(AppRoute.referrals)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Color.clear.frame(height: 120) // Bottom padding for floating tab bar
                    }
                }
            }
        }
    }

    private var dashboardHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome back,")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.lmTextSecondary)
                
                Text(auth.currentUser?.fullName ?? "User")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.lmPrimary)
            }
            Spacer()
            NotificationButton()
                .padding(6)
                .background(Circle().fill(Color.white.opacity(0.9)))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 24)
        .padding(.top, 75)
    }

    @ViewBuilder
    private var caseProgressSection: some View {
        let activeCases = firestore.cases.filter { $0.status.lowercased() != "closed" }
        if let latestCase = activeCases.sorted(by: { ($0.createdDate ?? Date.distantPast) > ($1.createdDate ?? Date.distantPast) }).first {
            VStack(alignment: .leading, spacing: 12) {
                Text("Active Case Progress")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.lmPrimary)
                    .padding(.horizontal, 24)
                
                Button {
                    navPath.append(latestCase)
                } label: {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(latestCase.title)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.lmPrimary)
                                Text("Status: \(latestCase.status)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.lmTextSecondary)
                            }
                            Spacer()
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.green.opacity(0.3))
                        }
                        
                        let progress = latestCase.stages.isEmpty ? 0.0 : Double(latestCase.stages.filter({ $0.isCompleted }).count) / Double(latestCase.stages.count)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("\(Int(progress * 100))%")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.lmPrimary)
                                Spacer()
                                Text("\(latestCase.stages.filter({ $0.isCompleted }).count) / \(latestCase.stages.count) Stages")
                                    .font(.system(size: 10))
                                    .foregroundColor(.lmTextSecondary)
                            }
                            
                            ProgressView(value: progress)
                                .accentColor(.green)
                                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
            }
        }
    }

    @ViewBuilder
    private var upcomingAppointmentsSection: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let upcoming = firestore.appointments.filter {
            let s = $0.status.lowercased()
            let isUpcoming = calendar.startOfDay(for: $0.date) >= today
            return isUpcoming && (s == "confirmed" || s == "pending" || s == "in progress")
        }.prefix(5)
        
        if !upcoming.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Upcoming Appointments")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    Spacer()
                    NavigationLink(value: AppRoute.allAppointments) {
                        Text("See All")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.lmPrimary.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(upcoming) { appointment in
                            appointmentCard(appointment)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 2)
                }
            }
            .padding(.top, 10)
        }
    }

    private func appointmentCard(_ appointment: FBAppointment) -> some View {
        let isOverdue = appointment.date < Date()
        let themeColor = isOverdue ? Color.red : Color.green
        
        return NavigationLink(value: appointment) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(themeColor.opacity(0.1))
                            .frame(width: 32, height: 32)
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(themeColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        let dayText = appointmentDay(for: appointment.date)
                        Text(dayText)
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(dayText == "TODAY" ? .white : themeColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(dayText == "TODAY" ? themeColor : Color.clear)
                            .clipShape(Capsule())
                        
                        Text(appointment.time)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.lmPrimary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: appointment.specialtyIcon)
                        .font(.system(size: 16))
                        .foregroundColor(.lmPrimary.opacity(0.2))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(appointment.lawyerName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    Text(appointment.service)
                        .font(.system(size: 12))
                        .foregroundColor(.lmTextSecondary)
                }
                
                if isOverdue {
                    HStack {
                        Spacer()
                        Text("Overdue")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(18)
            .frame(width: 200)
            .background(themeColor.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(themeColor.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
    
    private func appointmentDay(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "TODAY"
        } else if calendar.isDateInTomorrow(date) {
            return "TOMORROW"
        } else {
            let f = DateFormatter()
            f.dateFormat = "EEE, MMM dd"
            return f.string(from: date).uppercased()
        }
    }
}

private struct ClientHomeNavigationDestinations: ViewModifier {
    @Binding var navPath: NavigationPath
    @Binding var activeConversation: FBConversation?

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: Lawyer.self) { lawyer in
                LawyerDetailView(lawyer: lawyer, navPath: $navPath, activeConversation: $activeConversation)
            }
            .navigationDestination(for: ReferralLawyerContext.self) { context in
                LawyerDetailView(lawyer: context.lawyer, referringLawyerName: context.referringLawyerName, navPath: $navPath, activeConversation: $activeConversation)
            }
            .navigationDestination(for: FBAppointment.self) { appointment in
                MyCaseDetailsView(initialAppointment: appointment, navPath: $navPath, activeConversation: $activeConversation)
            }
            .navigationDestination(for: ClientHomeView.AppRoute.self) { route in
                switch route {
                case .myCases:
                    MyCasesView(navPath: $navPath, activeConversation: $activeConversation)
                case .documents:
                    AdvisoryListView()
                case .notifications:
                    NotificationsView(navPath: $navPath, activeConversation: $activeConversation)
                case .booking(let lawyer):
                    BookingView(lawyer: lawyer)
                case .allAppointments:
                    ClientAllAppointmentsListView()
                case .referrals:
                    ReferralNetworkView(navPath: $navPath, activeConversation: $activeConversation)
                }
            }
            .navigationDestination(for: FBAdvisoryDocument.self) { doc in
                DocumentDetailView(document: doc)
            }
            .navigationDestination(for: FBLegalCase.self) { clientCase in
                CaseDetailView(clientCase: clientCase, navPath: $navPath, activeConversation: $activeConversation)
            }
            .navigationDestination(item: $activeConversation) { conversation in
                ChatDetailView(conversation: conversation)
            }
            .navigationDestination(for: ProfileRoute.self) { route in
                switch route {
                case .personalInfo:
                    PersonalInfoView()
                case .security:
                    SecurityView()
                case .biometrics:
                    BiometricsView()
                case .profileNotifications:
                    ProfileNotificationsView()
                case .termsOfService:
                    TermsView()
                case .privacyPolicy:
                    PrivacyView()
                case .myUploads:
                    LawyerMyUploadsView()
                case .accessibility:
                    AccessibilitySettingsView()
                }
            }
    }
}

// BlobTopRight is removed in favor of GreenBlobBackground(style: .client)

// MARK: - Find Lawyer search card
private struct FindLawyerCard: View {
    @Binding var searchQuery: String
    @Binding var selectedTab: LawMateTab
    @Binding var navPath: NavigationPath

    var lawyers: [Lawyer] {
        FirestoreManager.shared.lawyers.map { user in
            let lat = user.latitude ?? 6.9271
            let lng = user.longitude ?? 79.8612
            
            return Lawyer(
                id: user.id,
                name: user.fullName,
                specialty: user.specialty ?? "General Practice",
                bio: user.bio ?? "Professional Lawyer",
                description: user.bio ?? "",
                experience: user.experience ?? "5 YEARS",
                experienceYears: 5,
                casesWon: user.casesWon ?? "0",
                wonCount: 0,
                rating: user.rating ?? 0.0,
                reviewCount: user.reviewCount ?? 0,
                location: user.address ?? "Colombo, Sri Lanka",
                image: user.profileImage ?? "",
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
            )
        }
    }

    var suggestions: [Lawyer] {
        guard !searchQuery.isEmpty else { return [] }
        return lawyers.filter { lawyer in
            lawyer.name.lowercased().contains(searchQuery.lowercased()) ||
            lawyer.specialty.lowercased().contains(searchQuery.lowercased())
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            LawMateSearchBar(text: $searchQuery, placeholder: "Search for lawyer, service...") {
                // When user submits search, switch to lawyers tab
                if !searchQuery.isEmpty {
                    selectedTab = .lawyers
                }
            }
            
            if !suggestions.isEmpty {
                suggestionsListView
            }
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var suggestionsListView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(suggestions.prefix(3)) { lawyer in
                Button {
                    searchQuery = lawyer.name
                    navPath.append(lawyer)
                } label: {
                    HStack(spacing: 12) {
                        LawMateAvatar(url: lawyer.image, name: lawyer.name, size: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lawyer.name)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.lmPrimary)
                            Text(lawyer.specialty)
                                .font(.system(size: 11))
                                .foregroundColor(.lmTextSecondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.left")
                            .font(.system(size: 12))
                            .foregroundColor(.lmPrimary.opacity(0.3))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)
                
                if lawyer.id != suggestions.prefix(3).last?.id {
                    Divider()
                        .padding(.horizontal, 16)
                }
            }
        }
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.top, 8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

private struct ClientActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 50, height: 50)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.lmPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}



#Preview {
    ClientHomeView()
}


// MARK: - Client All Appointments List View
public struct ClientAllAppointmentsListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firestore = FirestoreManager.shared
    @State private var selectedTab = 0 // 0: Upcoming, 1: Completed
    
    public init() {}
    
    var upcomingAppointments: [FBAppointment] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return firestore.appointments.filter {
            let s = $0.status.lowercased()
            let isUpcoming = calendar.startOfDay(for: $0.date) >= today
            return isUpcoming && (s == "confirmed" || s == "pending" || s == "in progress")
        }.sorted { $0.date > $1.date }
    }
    
    var completedAppointments: [FBAppointment] {
        firestore.appointments.filter {
            let s = $0.status.lowercased()
            return s == "done" || s == "cancelled"
        }.sorted { $0.date > $1.date }
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Green blob top-left (Client Style)
            GreenBlobBackground(style: .client)
                .frame(height: 300)
            
            VStack(spacing: 0) {
                // MARK: Custom Header
                LawMateNavigationBar(
                    title: "My Appointments",
                    showBack: true,
                    showNotification: true,
                    onBack: { dismiss() }
                )
                .padding(.top, 65)
                .zIndex(10)
                
                // MARK: Tab Switcher
                HStack(spacing: 0) {
                    TabButton(title: "Upcoming", isSelected: selectedTab == 0) {
                        withAnimation(.spring()) { selectedTab = 0 }
                    }
                    TabButton(title: "Completed", isSelected: selectedTab == 1) {
                        withAnimation(.spring()) { selectedTab = 1 }
                    }
                }
                .padding(4)
                .background(Color.black.opacity(0.05))
                .clipShape(Capsule())
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // MARK: List Content
                ScrollView(showsIndicators: false) {
                    let displayList = selectedTab == 0 ? upcomingAppointments : completedAppointments
                    
                    if displayList.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: selectedTab == 0 ? "calendar.badge.plus" : "clock.arrow.circlepath")
                                .font(.system(size: 60))
                                .foregroundColor(.lmPrimary.opacity(0.2))
                                .padding(.top, 100)
                            
                            Text(selectedTab == 0 ? "No upcoming appointments." : "No completed records found.")
                                .font(.lmBody)
                                .foregroundColor(.lmTextSecondary)
                        }
                    } else {
                        VStack(spacing: 16) {
                            ForEach(displayList) { appointment in
                                NavigationLink(value: appointment) {
                                    AppointmentRowView(appointment: appointment)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(24)
                        .padding(.bottom, 120)
                    }
                }
            }
            
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
    }
}
