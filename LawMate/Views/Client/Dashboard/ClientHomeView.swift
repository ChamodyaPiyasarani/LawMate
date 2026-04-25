import SwiftUI
import MapKit

struct ClientHomeView: View {
    @State private var selectedTab:  LawMateTab = .home
    @State private var searchQuery:  String = ""
    @State private var navPath = NavigationPath()
    @State private var activeConversation: FBConversation? = nil
    @State private var pendingChatId: String? = nil
    @AppStorage("biometricsEnabled") private var biometricsEnabled = false
    @State private var showBiometricOptIn = false
    @StateObject private var firestore = FirestoreManager.shared
    @StateObject private var notifications = NotificationManager.shared
    @ObservedObject private var auth = AuthService.shared
    
    // Simple routes for screens without complex data models
    enum AppRoute: Hashable {
        case myCases, documents, notifications, booking(Lawyer?), allAppointments
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.lmBackground.ignoresSafeArea()
            
            NavigationStack(path: $navPath) {
                VStack(spacing: 0) {
                    if selectedTab == .home {
                        // MARK: Home Content
                        ScrollView(showsIndicators: false) {
                            ZStack(alignment: .topTrailing) {
                                // Green blob top-left (Client Style)
                                GreenBlobBackground(style: .client)
                                    .frame(height: 300)

                                VStack(alignment: .leading, spacing: 32) {
                                    // MARK: Top bar
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Hello, \(auth.currentUser?.fullName.split(separator: " ").first ?? "User") !")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.lmPrimary)

                                            // Hero text — two-tone
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
                                            navPath.append(AppRoute.notifications)
                                        })
                                    }
                                    .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // MARK: Upcoming Appointments Section
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let upcoming = FirestoreManager.shared.appointments.filter {
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
                                    let isHearing = appointment.service.localizedCaseInsensitiveContains("hearing") ||
                                        appointment.description.localizedCaseInsensitiveContains("hearing")
                                    NavigationLink(value: appointment) {
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                Label(appointment.time, systemImage: "clock.fill")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.lmPrimary)
                                                
                                                Spacer()
                                                
                                                Image(systemName: appointment.specialtyIcon)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.lmPrimary.opacity(0.3))
                                            }
                                            
                                            Text(appointment.lawyerName)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.lmPrimary)
                                            
                                            Text(appointment.service)
                                                .font(.system(size: 11))
                                                .foregroundColor(.lmTextSecondary)
                                        }
                                        .padding(16)
                                        .frame(width: 160)
                                        .background(isHearing ? Color.orange.opacity(0.12) : Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.top, 10)
                }
                

                                    // MARK: Find My Lawyer card
                                    FindLawyerCard(searchQuery: $searchQuery, selectedTab: $selectedTab, navPath: $navPath)
                                        .padding(.horizontal, 24)

                                    // MARK: My Cases card
                                    HomeFeatureCard(
                                        title: "My Cases",
                                        description: "Detailed Breakthroughs On Current Legislation And Your Rights In The Modern World.",
                                        imageName: "doc.text.fill",
                                        imageOnLeft: false,
                                        route: .myCases
                                    )
                                    .padding(.horizontal, 24)

                                    // MARK: Document Templates card
                                    HomeFeatureCard(
                                        title: "Document Templates",
                                        description: "Standard Contracts, NDAs, And More. Ready For Signature.",
                                        imageName: "doc.on.doc.fill",
                                        imageOnLeft: true,
                                        route: .documents
                                    )
                                    .padding(.horizontal, 24)

                                    // Bottom padding for TabBar
                                    Color.clear.frame(height: 120)
                                }
                            }
                        }
                    } else if selectedTab == .lawyers {
                        // MARK: Lawyers Content
                        LawyersListView(onBack: {
                            selectedTab = .home
                        })
                    } else if selectedTab == .booking {
                        // MARK: Booking Content
                        BookingDetailsView(onBack: {
                            selectedTab = .home
                        })
                    } else if selectedTab == .messages {
                        // MARK: Messages Content
                        MessagesListView(onBack: {
                            selectedTab = .home
                        }, onSelect: { conversation in
                            activeConversation = conversation
                        })
                    } else {
                        // MARK: Profile Content
                        ProfileView(onBack: {
                            selectedTab = .home
                        })
                    }
                }
                .navigationDestination(for: Lawyer.self) { lawyer in
                    LawyerDetailView(lawyer: lawyer, activeConversation: $activeConversation)
                }
                .navigationDestination(for: FBAppointment.self) { appointment in
                    MyCaseDetailsView(appointment: appointment)
                }
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .myCases:
                        MyCasesView()
                    case .documents:
                        AdvisoryListView()
                    case .notifications:
                        NotificationsView()
                    case .booking(let lawyer):
                        BookingView(lawyer: lawyer)
                    case .allAppointments:
                        ClientAllAppointmentsListView()
                    }
                }
                .navigationDestination(for: FBAdvisoryDocument.self) { doc in
                    DocumentDetailView(document: doc)
                }
                .navigationDestination(for: FBLegalCase.self) { clientCase in
                    CaseDetailView(clientCase: clientCase)
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
                .navigationBarBackButtonHidden(true)
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
                // Handle Deep Linking from Notifications
                .onChange(of: notifications.pendingRoute) { _, route in
                    guard let route = route else { return }
                    
                    switch route {
                    case .chat(let conversationId):
                        // 1. Switch to messages tab
                        selectedTab = .messages
                        // 2. Clear stack first for a clean push
                        navPath = NavigationPath()
                        pendingChatId = conversationId
                        tryNavigateToPendingChat()
                    case .notificationCenter:
                        navPath.append(AppRoute.notifications)
                    case .myCases:
                        // Switch to home and navigate to my cases
                        selectedTab = .home
                        navPath.append(AppRoute.myCases)
                    }
                    
                    // Clear the pending route
                    notifications.pendingRoute = nil
                }
                .toolbar(.hidden, for: .navigationBar)
            }
            
            // MARK: Global Tab Bar
            if navPath.isEmpty && activeConversation == nil {
                VStack {
                    Spacer()
                    TabBarView(selectedTab: $selectedTab, role: .client)
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
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
                FirestoreManager.shared.startSync(role: user.role, userId: user.id)
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
}

// BlobTopRight is removed in favor of GreenBlobBackground(style: .client)

// MARK: - Find Lawyer search card
private struct FindLawyerCard: View {
    @Binding var searchQuery: String
    @Binding var selectedTab: LawMateTab
    @Binding var navPath: NavigationPath

    var lawyers: [Lawyer] {
        FirestoreManager.shared.lawyers.map { user in
            Lawyer(
                id: user.id,
                name: user.fullName,
                specialty: user.specialty ?? "General Practice",
                bio: user.bio ?? "Professional Lawyer",
                description: user.bio ?? "",
                experience: user.experience ?? "5 YEARS",
                experienceYears: 5,
                casesWon: user.casesWon ?? "0",
                wonCount: 0,
                rating: 4.8,
                location: "Colombo, Sri Lanka",
                image: user.profileImage ?? "",
                coordinate: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)
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
        VStack(spacing: 16) {
            VStack(spacing: 0) {
                // Search field
                LawMateSearchBar(text: $searchQuery, placeholder: "Search by name or specialization...")
                
                if !suggestions.isEmpty {
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

            // CTA button
            Button {
                if let match = lawyers.first(where: { $0.name.lowercased() == searchQuery.lowercased() }) {
                    navPath.append(match)
                } else {
                    withAnimation(.spring()) {
                        selectedTab = .lawyers
                    }
                }
            } label: {
                HStack {
                    Spacer()
                    Text("Find My Lawyer →")
                        .font(.lmButton)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(Color.lmPrimary)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(20) // Balanced padding
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24)) // Refined radius
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Home feature card (My Cases / Document Templates)
private struct HomeFeatureCard: View {
    let title: String
    let description: String
    let imageName: String
    let imageOnLeft: Bool
    let route: ClientHomeView.AppRoute

    var body: some View {
        NavigationLink(value: route) {
            HStack(alignment: .center, spacing: 16) {
                if imageOnLeft {
                    featureIcon
                }

                VStack(alignment: imageOnLeft ? .trailing : .leading, spacing: 6) {
                    Text(title)
                        .font(.lmHeading)
                        .foregroundColor(.lmPrimary)
                        .multilineTextAlignment(imageOnLeft ? .trailing : .leading)

                    Text(description)
                        .font(.lmCaption)
                        .foregroundColor(.lmTextSecondary.opacity(0.7))
                        .multilineTextAlignment(imageOnLeft ? .trailing : .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: imageOnLeft ? .trailing : .leading)

                if !imageOnLeft {
                    featureIcon
                }
            }
            .padding(20) // Balanced padding
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24)) // Refined radius
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var featureIcon: some View {
        Image(systemName: imageName)
            .font(.system(size: 60)) // Refined large icon
            .foregroundColor(Color.lmPrimary.opacity(0.05)) 
            .overlay(
                Image(systemName: imageName)
                    .font(.system(size: 24))
                    .foregroundColor(Color.lmPrimary.opacity(0.4))
            )
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
                .padding(.top, 64)
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
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
    }
}
