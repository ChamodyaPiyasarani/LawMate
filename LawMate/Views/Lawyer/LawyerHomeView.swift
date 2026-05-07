import SwiftUI
import EventKit

enum LawyerRoute: Hashable {
    case addCase
    case uploadAdvisory
    case notifications
    case referrals
    case hearings
}

struct LawyerHomeView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @AppStorage("userRole") private var storedRole: UserRole = .lawyer
    @State private var selectedTab: LawMateTab = .home
    @State private var navPath = NavigationPath()
    @State private var activeConversation: FBConversation? = nil
    @State private var pendingChatId: String? = nil
    @AppStorage("biometricsEnabled") private var biometricsEnabled = false
    @State private var showBiometricOptIn = false
    @EnvironmentObject var firestore: FirestoreManager
    @EnvironmentObject var eventService: EventKitService
    @EnvironmentObject var notifications: NotificationManager
    @EnvironmentObject var auth: AuthService
    @State private var todayEvents: [EKEvent] = []
    @State private var weekEvents: [EKEvent] = []
    
    private var filteredTodayEvents: [EKEvent] {
        todayEvents.filter { event in
            // 1. Filter out appointments that are already in todayAppointments
            let isAppointment = todayAppointments.contains { appt in
                let titleMatches = event.title.contains(appt.service) && (event.title.contains(appt.clientName) || event.title.contains(appt.lawyerName))
                return titleMatches && Calendar.current.isDate(event.startDate, inSameDayAs: appt.date)
            }
            if isAppointment { return false }
            
            // 2. Filter out hearings that are already in todayCaseHearings
            let isHearing = todayCaseHearings.contains { lCase in
                let titleMatches = event.title.contains(lCase.title)
                let dateMatches = lCase.hearingDates.contains(where: { Calendar.current.isDate(event.startDate, inSameDayAs: $0) }) || (lCase.hearingDate != nil && Calendar.current.isDate(event.startDate, inSameDayAs: lCase.hearingDate!))
                return titleMatches && dateMatches
            }
            if isHearing { return false }
            
            return true
        }
    }
    
    var todayAppointments: [FBAppointment] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return firestore.appointments.filter { 
            let s = $0.status.lowercased()
            return calendar.startOfDay(for: $0.date) == today && s != "cancelled" && s != "rejected" && s != "done" && s != "completed"
        }
    }
    
    var todayCaseHearings: [FBLegalCase] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return firestore.cases.filter { currentCase in
            if currentCase.hearingDates.contains(where: { calendar.startOfDay(for: $0) == today }) { return true }
            if let hDate = currentCase.hearingDate {
                return calendar.startOfDay(for: hDate) == today
            }
            return false
        }
    }
    
    var hearingsThisWeekCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        
        let caseHearings = firestore.cases.filter { currentCase in
            if currentCase.hearingDates.contains(where: { $0 >= today && $0 <= endOfWeek }) { return true }
            if let hDate = currentCase.hearingDate {
                return hDate >= today && hDate <= endOfWeek
            }
            return false
        }.count
        
        let calendarHearings = weekEvents.filter { 
            $0.title.lowercased().contains("hearing")
        }.count
        
        return caseHearings + calendarHearings
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.lmBackground.ignoresSafeArea()
            
            NavigationStack(path: $navPath) {
                VStack(spacing: 0) {
                    contentForSelectedTab
                }
                .navigationBarHidden(true)
                .ignoresSafeArea(edges: .top)
                .navigationDestination(item: $activeConversation) { conversation in
                    ChatDetailView(conversation: conversation)
                }
                .navigationDestination(for: FBLegalCase.self) { lawyerCase in
                    LawyerCaseDetailView(legalCase: lawyerCase)
                }
                .navigationDestination(for: FBAppointment.self) { appointment in
                    LawyerCalendarView(navPath: $navPath, activeConversation: $activeConversation, showBack: true) 
                }
                .navigationDestination(for: LawyerRoute.self) { route in
                    destinationForLawyerRoute(route)
                }
                .navigationDestination(for: ProfileRoute.self) { route in
                    destinationForProfileRoute(route)
                }
                .onAppear {
                    if UserDefaults.standard.bool(forKey: "shouldShowBiometricPrompt") {
                        showBiometricOptIn = true
                    }
                }
                .onChange(of: notifications.pendingRoute) { _, route in
                    handleNotificationRoute(route)
                }
                .alert("Enable Biometric Login?", isPresented: $showBiometricOptIn) {
                    biometricOptInButtons
                } message: {
                    Text("Would you like to use Face ID / Touch ID for faster login next time?")
                }
            }
            
            // Persistent Tab Bar
            if activeConversation == nil {
                VStack {
                    Spacer()
                    TabBarView(selectedTab: $selectedTab, role: .lawyer)
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
            if let user = AuthService.shared.currentUser {
                firestore.startSync(role: user.role, userId: user.id)
                fetchTodayEvents()
            }
        }
    }

    @ViewBuilder
    private var contentForSelectedTab: some View {
        switch selectedTab {
        case .home:
            dashboardView
        case .cases:
            LawyerCasesView(navPath: $navPath, activeConversation: $activeConversation)
        case .calendar:
            LawyerCalendarView(navPath: $navPath, activeConversation: $activeConversation, showBack: false)
        case .messages:
            MessagesListView(onBack: { selectedTab = .home }, onSelect: { conversation in
                activeConversation = conversation
            })
        case .profile:
            ProfileView(navPath: $navPath, activeConversation: $activeConversation, onBack: { selectedTab = .home })
        case .lawyers, .booking:
            EmptyView()
        }
    }

    private var dashboardView: some View {
        ZStack(alignment: .top) {
            GreenBlobBackground(style: .lawyer)
                .frame(height: 350)
                .offset(y: -50)
            
            VStack(spacing: 0) {
                dashboardHeader
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        statsCardsSection
                        
                        NavigationLink(value: LawyerRoute.hearings) {
                            HearingsCard(count: String(format: "%02d", hearingsThisWeekCount))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                        
                        actionButtonsSection
                        
                        schedulesSection
                        
                        Color.clear.frame(height: 120)
                    }
                    .padding(.top, 24)
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

    private var statsCardsSection: some View {
        HStack(spacing: 20) {
            DashboardStatCard(title: "Cases", value: String(format: "%02d", firestore.cases.count), isGreen: false)
            
            Button {
                withAnimation(.spring()) {
                    selectedTab = .calendar
                }
            } label: {
                DashboardStatCard(title: "Today\nAppointments", value: String(format: "%02d", filteredTodayEvents.count + todayAppointments.count), isGreen: true)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
    }

    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            LawyerActionButton(icon: "plus.circle.fill", title: "Add new case", color: .blue) {
                navPath.append(LawyerRoute.addCase)
            }
            LawyerActionButton(icon: "doc.badge.plus", title: "Add documents", color: .orange) {
                navPath.append(LawyerRoute.uploadAdvisory)
            }
            LawyerActionButton(icon: "arrowshape.turn.up.right.fill", title: "Referrals", color: .purple) {
                navPath.append(LawyerRoute.referrals)
            }
        }
        .padding(.horizontal, 24)
    }

    private var schedulesSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text("Today Schedules")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.lmPrimary)
                
                Spacer()
                
                Button {
                    withAnimation(.spring()) {
                        selectedTab = .calendar
                    }
                } label: {
                    Text("See All")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.lmPrimary)
                }
            }
            .padding(.horizontal, 24)

            VStack(spacing: 16) {
                if filteredTodayEvents.isEmpty && todayAppointments.isEmpty && todayCaseHearings.isEmpty {
                    Text("No schedules for today")
                        .font(.lmCaption)
                        .foregroundColor(.lmTextSecondary.opacity(0.5))
                        .padding()
                } else {
                    todaySchedulesList
                }
            }
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private var todaySchedulesList: some View {
        ForEach(todayCaseHearings) { lCase in
            let dateToUse = lCase.hearingDates.first(where: { Calendar.current.startOfDay(for: $0) == Calendar.current.startOfDay(for: Date()) }) ?? lCase.hearingDate ?? Date()
            ScheduleRow(
                time: formatTime(dateToUse),
                event: "Hearing: \(lCase.title)",
                category: lCase.clientName
            )
        }
        
        ForEach(todayAppointments) { appointment in
            Button {
                withAnimation(.spring()) {
                    selectedTab = .calendar
                }
            } label: {
                ScheduleRow(
                    time: formatTime(appointment.date),
                    event: "Appt: \(appointment.clientName)",
                    category: appointment.service,
                    statusTitle: appointment.statusTitle,
                    statusColor: appointment.statusColor
                )
            }
            .buttonStyle(.plain)
        }
        
        ForEach(filteredTodayEvents, id: \.eventIdentifier) { event in
            Button {
                withAnimation(.spring()) {
                    selectedTab = .calendar
                }
            } label: {
                ScheduleRow(
                    time: formatTime(event.startDate),
                    event: event.title,
                    category: event.notes?.replacingOccurrences(of: "Type: ", with: "") ?? "General"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var bottomTabBar: some View {
        Group {
            if navPath.isEmpty && activeConversation == nil {
                VStack {
                    Spacer()
                    TabBarView(selectedTab: $selectedTab, role: .lawyer)
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private func destinationForLawyerRoute(_ route: LawyerRoute) -> some View {
        switch route {
        case .addCase:
            AddCaseView()
        case .uploadAdvisory:
            UploadAdvisoryView()
        case .notifications: NotificationsView(navPath: $navPath, activeConversation: $activeConversation)
        case .referrals: ReferralRequestsView(activeConversation: $activeConversation)
        case .hearings: LawyerHearingsListView()
        }
    }

    @ViewBuilder
    private func destinationForProfileRoute(_ route: ProfileRoute) -> some View {
        switch route {
        case .personalInfo: PersonalInfoView()
        case .security: SecurityView()
        case .biometrics: BiometricsView()
        case .profileNotifications: ProfileNotificationsView()
        case .termsOfService: TermsView()
        case .privacyPolicy: PrivacyView()
        case .myUploads: LawyerMyUploadsView()
        case .accessibility: AccessibilitySettingsView()
        }
    }

    private func handleNotificationRoute(_ route: NotificationManager.DeepLinkRoute?) {
        guard let route = route else { return }
        
        // Reset navigation state for any route that moves the user to a specific detail view
        // to prevent "stacking" conflicts.
        switch route {
        case .chat, .myCases, .appointment, .lawyerProfile:
            navPath = NavigationPath()
            activeConversation = nil
        case .notificationCenter:
            break
        }
        
        switch route {
        case .chat(let conversationId):
            selectedTab = .messages
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                pendingChatId = conversationId
                tryNavigateToPendingChat()
            }
        case .notificationCenter:
            notifications.showNotifications = true
        case .myCases:
            selectedTab = .cases
        case .appointment(let appointmentId):
            if let appointment = firestore.appointments.first(where: { $0.id == appointmentId }) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    navPath.append(appointment)
                }
            } else {
                selectedTab = .home
            }
        case .lawyerProfile:
            // For lawyers, we can redirect to the referral network or just the notification center
            selectedTab = .profile
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                navPath.append(LawyerRoute.referrals)
            }
        }
        notifications.pendingRoute = nil
    }

    private var biometricOptInButtons: some View {
        Group {
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
    
    private func fetchTodayEvents() {
        if eventService.isAuthorized {
            todayEvents = eventService.fetchEvents(for: Date())
            weekEvents = eventService.fetchEventsForWeek(from: Date())
        } else {
            eventService.requestAccess { granted in
                if granted {
                    todayEvents = eventService.fetchEvents(for: Date())
                    weekEvents = eventService.fetchEventsForWeek(from: Date())
                }
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh.mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Subcomponents

private struct DashboardStatCard: View {
    let title: String
    let value: String
    let isGreen: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(value)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(isGreen ? .white : .lmPrimary)
                Spacer()
                Image(systemName: isGreen ? "calendar.badge.clock" : "briefcase.fill")
                    .font(.system(size: 20))
                    .foregroundColor(isGreen ? .white.opacity(0.6) : .lmPrimary.opacity(0.2))
            }
            
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isGreen ? .white.opacity(0.9) : .lmTextSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            ZStack {
                if isGreen {
                    LinearGradient(colors: [.lmPrimary, .lmPrimary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                } else {
                    Color.white
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: isGreen ? Color.lmPrimary.opacity(0.3) : Color.black.opacity(0.05), radius: 15, x: 0, y: 8)
    }
}

private struct HearingsCard: View {
    let count: String

    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hearings This Week")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.lmPrimary)
                Text("Your upcoming court sessions")
                    .font(.system(size: 12))
                    .foregroundColor(.lmTextSecondary.opacity(0.7))
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.lmPrimary.opacity(0.05))
                    .frame(width: 50, height: 50)
                
                Text(count)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.lmPrimary)
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
}

private struct LawyerActionButton: View {
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

private struct ScheduleRow: View {
    let time: String
    let event: String
    let category: String
    var statusTitle: String? = nil
    var statusColor: Color = .lmPrimary

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(time.split(separator: " ").first ?? "")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.lmPrimary)
                Text(time.split(separator: " ").last ?? "")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.lmTextSecondary)
            }
            .frame(width: 60, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lmPrimary)
                
                Text(category)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.lmTextSecondary.opacity(0.7))
            }
            
            Spacer()
            
            if let status = statusTitle {
                Text(status)
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(
            ZStack {
                Color.green.opacity(0.04) // Light green highlight
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.green.opacity(0.1), lineWidth: 1)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.01), radius: 5, x: 0, y: 2)
    }
}

private struct ComingSoonView: View {
    let title: String
    let icon: String
    let onBack: () -> Void
    
    var body: some View {
        ZStack {
            Color.lmBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                LawMateNavigationBar(title: title, showBack: true, showNotification: false, onBack: onBack)
                    .padding(.top, 65)
                
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(.lmPrimary.opacity(0.3))
                Text("\(title) coming soon")
                    .font(.lmBody)
                    .foregroundColor(.lmTextSecondary)
                Spacer()
            }
            
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    LawyerHomeView()
}

// MARK: - Lawyer Hearings List View
struct LawyerHearingsListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firestore: FirestoreManager
    @EnvironmentObject var auth: AuthService
    
    @State private var searchText = ""
    @State private var selectedTimeFrame = "Upcoming"
    
    private let timeFrames = ["Upcoming", "This Week", "Past"]
    
    var allHearings: [(case: FBLegalCase, hearing: FBHearingDate)] {
        var result: [(case: FBLegalCase, hearing: FBHearingDate)] = []
        for legalCase in firestore.cases {
            for hearing in legalCase.hearings {
                result.append((case: legalCase, hearing: hearing))
            }
        }
        return result.sorted { $0.hearing.date < $1.hearing.date }
    }
    
    var filteredHearings: [(case: FBLegalCase, hearing: FBHearingDate)] {
        allHearings.filter { item in
            let matchesSearch = searchText.isEmpty || 
                               item.case.clientName.localizedCaseInsensitiveContains(searchText) ||
                               item.hearing.location.localizedCaseInsensitiveContains(searchText) ||
                               item.hearing.notes.localizedCaseInsensitiveContains(searchText)
            
            let isUpcoming = item.hearing.date >= Calendar.current.startOfDay(for: Date())
            let matchesTimeFrame: Bool
            
            switch selectedTimeFrame {
            case "Upcoming":
                matchesTimeFrame = isUpcoming
            case "This Week":
                let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
                matchesTimeFrame = item.hearing.date >= Date() && item.hearing.date <= weekEnd
            case "Past":
                matchesTimeFrame = !isUpcoming
            default:
                matchesTimeFrame = true
            }
            
            return matchesSearch && matchesTimeFrame
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            GreenBlobBackground(style: .lawyer)
                .frame(height: 350)
                .offset(y: -50)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    LawMateBackButton(action: { dismiss() })
                    
                    Spacer()
                    
                    Text("Court Hearings")
                        .font(.lmHeading)
                        .foregroundColor(.lmPrimary)
                    
                    Spacer()
                    
                    // Invisible spacer for balance
                    Circle().fill(.clear).frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 65)
                .zIndex(10)
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Filters
                        VStack(spacing: 16) {
                            LawMateSearchBar(text: $searchText, placeholder: "Search client, court, or notes")
                            
                            HStack {
                                ForEach(timeFrames, id: \.self) { frame in
                                    FilterChip(title: frame, isSelected: selectedTimeFrame == frame) {
                                        selectedTimeFrame = frame
                                    }
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 30)
                        
                        // Hearings List
                        VStack(spacing: 16) {
                            if filteredHearings.isEmpty {
                                emptyState
                            } else {
                                ForEach(0..<filteredHearings.count, id: \.self) { index in
                                    let item = filteredHearings[index]
                                    HearingRowCard(hearingItem: item)
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
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.columns.fill")
                .font(.system(size: 48))
                .foregroundColor(.lmPrimary.opacity(0.1))
            Text("No hearings found")
                .font(.lmHeading)
                .foregroundColor(.lmPrimary.opacity(0.5))
            Text("Your courtroom schedule is clear.")
                .font(.lmCaption)
                .foregroundColor(.lmTextSecondary)
        }
        .padding(.vertical, 64)
    }
}

struct HearingRowCard: View {
    let hearingItem: (case: FBLegalCase, hearing: FBHearingDate)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(hearingItem.hearing.date))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    Text(formatTime(hearingItem.hearing.date))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.lmTextSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 10))
                    Text(hearingItem.hearing.location)
                        .font(.system(size: 10, weight: .bold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.lmPrimary.opacity(0.1))
                .foregroundColor(.lmPrimary)
                .clipShape(Capsule())
            }
            
            Divider().opacity(0.5)
            
            HStack(spacing: 12) {
                LawMateAvatar(url: hearingItem.case.clientImage, name: hearingItem.case.clientName, size: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(hearingItem.case.clientName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    Text(hearingItem.case.caseNumber)
                        .font(.system(size: 12))
                        .foregroundColor(.lmTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.lmPrimary.opacity(0.3))
            }
            
            if !hearingItem.hearing.notes.isEmpty {
                Text(hearingItem.hearing.notes)
                    .font(.system(size: 12))
                    .foregroundColor(.lmTextSecondary.opacity(0.8))
                    .padding(.top, 4)
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
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM dd"
        return f.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "hh:mm a"
        return f.string(from: date)
    }
}

