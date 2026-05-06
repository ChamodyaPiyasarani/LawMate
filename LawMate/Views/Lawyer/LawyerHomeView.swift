import SwiftUI
import EventKit

enum LawyerRoute: Hashable {
    case addCase
    case uploadAdvisory
    case notifications
    case referrals
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
    
    var todayAppointments: [FBAppointment] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return firestore.appointments.filter { 
            let s = $0.status.lowercased()
            return calendar.startOfDay(for: $0.date) == today && s != "cancelled" && s != "rejected"
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
            
            bottomTabBar
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
                        
                        HearingsCard(count: String(format: "%02d", hearingsThisWeekCount))
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
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello, \(auth.currentUser?.fullName ?? "User") !")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.lmPrimary)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Justice,")
                        .font(.lmHero)
                        .foregroundColor(.lmPrimary)
                    Text("Refined.")
                        .font(.lmHero)
                        .foregroundColor(.lmTextSecondary.opacity(0.5))
                }
            }
            Spacer()
            
            NotificationButton(action: {
                navPath.append(LawyerRoute.notifications)
            })
        }
        .padding(.horizontal, 24)
        .padding(.top, 65)
    }

    private var statsCardsSection: some View {
        HStack(spacing: 20) {
            DashboardStatCard(title: "Cases", value: String(format: "%02d", firestore.cases.count), isGreen: false)
            
            Button {
                withAnimation(.spring()) {
                    selectedTab = .calendar
                }
            } label: {
                DashboardStatCard(title: "Today\nAppointments", value: String(format: "%02d", todayEvents.count + todayAppointments.count), isGreen: true)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
    }

    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            ActionPill(icon: "plus.circle.fill", title: "Add new case") {
                navPath.append(LawyerRoute.addCase)
            }
            ActionPill(icon: "doc.badge.plus", title: "Add documents") {
                navPath.append(LawyerRoute.uploadAdvisory)
            }
            ActionPill(icon: "arrowshape.turn.up.right.fill", title: "Referrals") {
                navPath.append(LawyerRoute.referrals)
            }
        }
        .padding(.horizontal, 24)
    }

    private var schedulesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today Schedules")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.lmTextSecondary.opacity(0.6))
                
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
                if todayEvents.isEmpty && todayAppointments.isEmpty && todayCaseHearings.isEmpty {
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
        
        ForEach(todayEvents, id: \.eventIdentifier) { event in
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
        case .notifications:
            NotificationsView(navPath: $navPath, activeConversation: $activeConversation)
        case .referrals:
            ReferralRequestsView(activeConversation: $activeConversation)
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
        case .referrals: ReferralNetworkView(navPath: $navPath, activeConversation: $activeConversation)
        }
    }

    private func handleNotificationRoute(_ route: NotificationManager.DeepLinkRoute?) {
        guard let route = route else { return }
        switch route {
        case .chat(let conversationId):
            selectedTab = .messages
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                navPath = NavigationPath()
                pendingChatId = conversationId
                tryNavigateToPendingChat()
            }
        case .notificationCenter:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                navPath.append(LawyerRoute.notifications)
            }
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
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(isGreen ? .white : .lmPrimary)
            
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isGreen ? .white : .lmTextSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(isGreen ? Color.lmPrimary : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

private struct HearingsCard: View {
    let count: String

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.lmPrimary.opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.lmPrimary)
            }
            
            Text("Hearings\nThis Week")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.lmPrimary)
            
            Spacer()
            
            Text(count)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.lmTextSecondary.opacity(0.3))
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

private struct ActionPill: View {
    let icon: String
    let title: String
    let action: () -> Void

    private var pillBackground: Color {
        AccessibilityManager.shared.effectiveHighContrast ? .black : Color(red: 0.05, green: 0.25, blue: 0.15)
    }

    private var pillForeground: Color {
        AccessibilityManager.shared.effectiveHighContrast ? .white : .white
    }

    private var iconBackground: Color {
        AccessibilityManager.shared.effectiveHighContrast ? .white.opacity(0.25) : Color.white.opacity(0.2)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(iconBackground)
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(pillForeground)
                }

                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(pillForeground)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
            }
            .frame(maxWidth: .infinity, minHeight: 70)
            .padding(.vertical, 10)
            .background(pillBackground)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
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
            // Minimalist timeline indicator
            VStack {
                Text(time.split(separator: " ").first ?? "")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.lmTextPrimary)
                Text(time.split(separator: " ").last ?? "")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.lmTextPrimary.opacity(0.6))
            }
            .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lmPrimary)
                
                Text(category)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.lmTextSecondary.opacity(0.5))
            }
            
            Spacer()
            
            if let status = statusTitle {
                Text(status)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            HStack {
                Rectangle()
                    .fill(Color.lmPrimary)
                    .frame(width: 4)
                    .padding(.vertical, 12)
                Spacer()
            }
        )
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

