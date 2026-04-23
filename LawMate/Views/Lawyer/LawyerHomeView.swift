import SwiftUI
import EventKit

enum LawyerRoute: Hashable {
    case addCase
    case uploadAdvisory
    case notifications
}

struct LawyerHomeView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @AppStorage("userRole") private var storedRole: UserRole = .lawyer
    @State private var selectedTab: LawMateTab = .home
    @State private var navPath = NavigationPath()
    @AppStorage("biometricsEnabled") private var biometricsEnabled = false
    @State private var showBiometricOptIn = false
    @StateObject private var firestore = FirestoreManager.shared
    @StateObject private var eventService = EventKitService.shared
    @StateObject private var notifications = NotificationManager.shared
    @State private var todayEvents: [EKEvent] = []
    
    var todayAppointments: [FBAppointment] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return firestore.appointments.filter { calendar.startOfDay(for: $0.date) == today }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.lmBackground.ignoresSafeArea()
            
            NavigationStack(path: $navPath) {
                VStack(spacing: 0) {
                    if selectedTab == .home {
                        // MARK: Lawyer Home Dashboard
                        ZStack(alignment: .top) {
                            // Fixed Background Blob (Right-aligned for Lawyer)
                            GreenBlobBackground(style: .lawyer)
                                .frame(height: 350)
                                .offset(y: -50) // Adjust to sit behind header
                            
                            VStack(spacing: 0) {
                                // MARK: Fixed Header (Sticky)
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Welcome to LawMate !")
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
                                    
                                    // Notification Bell as per image
                                    NotificationButton(badgeCount: firestore.unreadNotificationsCount, action: {
                                        navPath.append(LawyerRoute.notifications)
                                    })
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 20)
                                .background(Color.lmBackground.opacity(0.01)) // Subtle touch area

                                // MARK: Scrollable Content
                                ScrollView(showsIndicators: false) {
                                    VStack(alignment: .leading, spacing: 28) {
                                        // MARK: Stats Cards
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

                                        // MARK: Hearings Card
                                        HearingsCard(count: String(format: "%02d", todayEvents.filter({ $0.title.lowercased().contains("hearing") }).count))
                                            .padding(.horizontal, 24)

                                        // MARK: Action Buttons
                                        HStack(spacing: 16) {
                                            ActionPill(icon: "plus.circle.fill", title: "Add new case") {
                                                navPath.append(LawyerRoute.addCase)
                                            }
                                            ActionPill(icon: "doc.badge.plus", title: "Add Documents") {
                                                navPath.append(LawyerRoute.uploadAdvisory)
                                            }
                                        }
                                        .padding(.horizontal, 24)

                                        // MARK: Schedules
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
                                                if todayEvents.isEmpty && todayAppointments.isEmpty {
                                                    Text("No schedules for today")
                                                        .font(.lmCaption)
                                                        .foregroundColor(.lmTextSecondary.opacity(0.5))
                                                        .padding()
                                                } else {
                                                    // LawMate Appointments (Priority)
                                                    ForEach(todayAppointments) { appointment in
                                                        Button {
                                                            withAnimation(.spring()) {
                                                                selectedTab = .calendar
                                                            }
                                                        } label: {
                                                            ScheduleRow(
                                                                time: formatTime(appointment.date),
                                                                event: "Appt: \(appointment.clientName)",
                                                                category: appointment.service
                                                            )
                                                        }
                                                        .buttonStyle(.plain)
                                                    }
                                                    
                                                    // System Events
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
                                            }
                                            .padding(.horizontal, 24)
                                        }

                                        // TabBar Space
                                        Color.clear.frame(height: 120)
                                    }
                                    .padding(.top, 24)
                                }
                            }
                        }
                    } else if selectedTab == .cases {
                        LawyerCasesView()
                    } else if selectedTab == .calendar {
                        LawyerCalendarView(showBack: false)
                    } else if selectedTab == .messages {
                        MessagesListView(onBack: { selectedTab = .home }, onSelect: { conversation in
                            navPath.append(conversation)
                        })
                    } else {
                        ProfileView(onBack: { selectedTab = .home })
                    }
                }
                .navigationBarHidden(true)
                .navigationDestination(for: FBConversation.self) { conversation in
                    ChatDetailView(conversation: conversation)
                }
                .navigationDestination(for: LawyerRoute.self) { route in
                    switch route {
                    case .addCase:
                        AddCaseView()
                    case .uploadAdvisory:
                        UploadAdvisoryView()
                    case .notifications:
                        NotificationsView()
                    }
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
                .onAppear {
                    if UserDefaults.standard.bool(forKey: "shouldShowBiometricPrompt") {
                        showBiometricOptIn = true
                    }
                }
                // Handle Deep Linking from Notifications
                .onChange(of: notifications.pendingRoute) { _, route in
                    guard let route = route else { return }
                    
                    switch route {
                    case .chat(let conversationId):
                        // 1. Switch to messages tab
                        selectedTab = .messages
                        // 2. Clear stack first for a clean push
                        navPath = NavigationPath()
                        
                        // 3. Find and push
                        if let conv = firestore.conversations.first(where: { $0.id == conversationId }) {
                            navPath.append(conv)
                        } else {
                            // If not found in list yet, construct a basic one so navigation succeeds
                            // The ChatDetailView will load the messages based on the ID anyway
                            let placeholder = FBConversation(
                                id: conversationId,
                                participants: [], // Will be filled by listener
                                lastMessageAt: Date()
                            )
                            navPath.append(placeholder)
                        }
                    case .notificationCenter:
                        navPath.append(LawyerRoute.notifications)
                    }
                    
                    // Clear the pending route
                    notifications.pendingRoute = nil
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
            }
            
            // MARK: Global Tab Bar (Lawyer Role)
            if navPath.isEmpty {
                VStack {
                    Spacer()
                    TabBarView(selectedTab: $selectedTab, role: .lawyer)
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: navPath.isEmpty)
        .onAppear {
            if let user = AuthService.shared.currentUser {
                firestore.startSync(role: user.role, userId: user.id)
                fetchTodayEvents()
            }
        }
    }
    
    private func fetchTodayEvents() {
        if eventService.isAuthorized {
            todayEvents = eventService.fetchEvents(for: Date())
        } else {
            eventService.requestAccess { granted in
                if granted {
                    todayEvents = eventService.fetchEvents(for: Date())
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

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.leading, 6)
            .padding(.trailing, 16)
            .padding(.vertical, 6)
            .background(Color(red: 0.05, green: 0.25, blue: 0.15)) // Darker green for pills
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ScheduleRow: View {
    let time: String
    let event: String
    let category: String

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
                    .padding(.top, 64)
                
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(.lmPrimary.opacity(0.3))
                Text("\(title) coming soon")
                    .font(.lmBody)
                    .foregroundColor(.lmTextSecondary)
                Spacer()
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    LawyerHomeView()
}

