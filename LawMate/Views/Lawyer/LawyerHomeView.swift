import SwiftUI
import EventKit

enum LawyerRoute: Hashable {
    case addCase
    case uploadAdvisory
}

struct LawyerHomeView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @AppStorage("userRole") private var storedRole: UserRole = .lawyer
    @State private var selectedTab: LawMateTab = .home
    @State private var navPath = NavigationPath()

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
                                    NotificationButton(badgeCount: 3, action: {})
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 64)
                                .background(Color.lmBackground.opacity(0.01)) // Subtle touch area

                                // MARK: Scrollable Content
                                ScrollView(showsIndicators: false) {
                                    VStack(alignment: .leading, spacing: 28) {
                                        // MARK: Stats Cards
                                        HStack(spacing: 20) {
                                            DashboardStatCard(title: "Cases", value: "07", isGreen: false)
                                            DashboardStatCard(title: "Today\nAppointments", value: "03", isGreen: true)
                                        }
                                        .padding(.horizontal, 24)

                                        // MARK: Hearings Card
                                        HearingsCard(count: "09")
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
                                            Text("Today Schedules")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.lmTextSecondary.opacity(0.6))
                                                .padding(.horizontal, 24)

                                            VStack(spacing: 16) {
                                                ScheduleRow(time: "10.00 AM", event: "Consultation : Anuradha Rnasinghe", category: "Family Law")
                                                ScheduleRow(time: "02.00 PM", event: "Hearing : Malsha Kavindi", category: "Divorce")
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
                        .ignoresSafeArea(edges: .top)
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
        .onChange(of: selectedTab) { _ in
            navPath = NavigationPath()
        }
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

