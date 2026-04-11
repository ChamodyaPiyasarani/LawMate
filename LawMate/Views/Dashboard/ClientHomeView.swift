import SwiftUI

struct ClientHomeView: View {
    @State private var selectedTab:  LawMateTab = .home
    @State private var searchQuery:  String = ""
    @State private var showMyCases: Bool = false
    @State private var showDocuments: Bool = false
    @State private var showNotifications: Bool = false
    @State private var navPath = NavigationPath()

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
                                            showNotifications = true
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
                                        action: {
                                            showMyCases = true
                                        }
                                    )
                                    .padding(.horizontal, 24)

                                    // MARK: Document Templates card
                                    HomeFeatureCard(
                                        title: "Document Templates",
                                        description: "Standard Contracts, NDAs, And More. Ready For Signature.",
                                        imageName: "doc.on.doc.fill",
                                        imageOnLeft: true,
                                        action: {
                                            showDocuments = true
                                        }
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
                .navigationDestination(isPresented: $showMyCases) {
                    MyCasesView()
                }
                .navigationDestination(isPresented: $showDocuments) {
                    DocumentsView()
                }
                .navigationDestination(isPresented: $showNotifications) {
                    NotificationsView()
                }
                .navigationDestination(for: ClientCase.self) { clientCase in
                    CaseDetailView(clientCase: clientCase)
                }
                .navigationDestination(for: ChatPreview.self) { chat in
                    ChatDetailView(chat: chat)
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
                    }
                }
                .navigationBarBackButtonHidden(true)
                .toolbar(.hidden, for: .navigationBar)
            }
            
            // MARK: Global Tab Bar
            if navPath.isEmpty && !showMyCases && !showDocuments && !showNotifications {
                VStack {
                    Spacer()
                    TabBarView(selectedTab: $selectedTab)
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: navPath.isEmpty && !showMyCases && !showDocuments && !showNotifications)
        .onChange(of: selectedTab) { _ in
            navPath = NavigationPath()
            showMyCases = false
            showDocuments = false
            showNotifications = false
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
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(.lmTextSecondary)
                TextField("Search by name or specialization...", text: $searchQuery)
                    .font(.lmField)
                    .foregroundColor(.lmTextPrimary)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )

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
    var action: () -> Void = {}

    var body: some View {
        Button {
            action()
        } label: {
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
