import SwiftUI

struct ClientHomeView: View {
    @State private var selectedTab:  LawMateTab = .home
    @State private var searchQuery:  String = ""
    @State private var navPath = NavigationPath()
    
    // Simple routes for screens without complex data models
    enum AppRoute: Hashable {
        case myCases, documents, notifications, booking(Lawyer)
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
                                            Text("Welcome to LawMate !")
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
                                        NotificationButton(badgeCount: 5, action: {
                                            navPath.append(AppRoute.notifications)
                                        })
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.top, 64)

                                    // MARK: Find My Lawyer card
                                    FindLawyerCard(searchQuery: $searchQuery, selectedTab: $selectedTab)
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
                        .ignoresSafeArea(edges: .top)
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
                            navPath.append(conversation)
                        })
                    } else {
                        // MARK: Profile Content
                        ProfileView(onBack: {
                            selectedTab = .home
                        })
                    }
                }
                .navigationDestination(for: Lawyer.self) { lawyer in
                    LawyerDetailView(lawyer: lawyer)
                }
                .navigationDestination(for: Booking.self) { booking in
                    MyCaseDetailsView(booking: booking)
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
                    }
                }
                .navigationDestination(for: AdvisoryDocument.self) { doc in
                    DocumentDetailView(document: doc)
                }
                .navigationDestination(for: FBLegalCase.self) { clientCase in
                    CaseDetailView(clientCase: clientCase)
                }
                .navigationDestination(for: FBConversation.self) { conversation in
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
                .toolbar(.hidden, for: .navigationBar)
            }
            
            // MARK: Global Tab Bar
            if navPath.isEmpty {
                VStack {
                    Spacer()
                    TabBarView(selectedTab: $selectedTab, role: .client)
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

// BlobTopRight is removed in favor of GreenBlobBackground(style: .client)

// MARK: - Find Lawyer search card
private struct FindLawyerCard: View {
    @Binding var searchQuery: String
    @Binding var selectedTab: LawMateTab

    var body: some View {
        VStack(spacing: 16) {
            // Search field
            LawMateSearchBar(text: $searchQuery, placeholder: "Search by name or specialization...")

            // CTA button
            Button {
                withAnimation(.spring()) {
                    selectedTab = .lawyers
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
