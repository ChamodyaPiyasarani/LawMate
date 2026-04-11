import SwiftUI

enum ProfileRoute: Hashable {
    case personalInfo
    case security
    case biometrics
    case profileNotifications
    case termsOfService
    case privacyPolicy
}

struct ProfileView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    var onBack: () -> Void = {}
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Green blob top-left
            GreenBlobBackground(style: .client)
                .frame(height: 300)
            
            VStack(spacing: 0) {
                // Header
                LawMateNavigationBar(
                    title: "Profile",
                    showBack: true,
                    showNotification: false,
                    showCamera: false,
                    notificationCount: 0,
                    onBack: onBack
                )
                .padding(.top, 64)
                .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // MARK: Profile Info
                        profileHeader
                        
                        // MARK: Sections
                        VStack(spacing: 24) {
                            menuSection(title: "Account", items: [
                                ("person", "Personal Information", ProfileRoute.personalInfo),
                                ("lock", "Security & Password", ProfileRoute.security),
                                ("faceid", "Biometric Settings", ProfileRoute.biometrics)
                            ])
                            
                            menuSection(title: "Preferences", items: [
                                ("bell", "Notifications", ProfileRoute.profileNotifications)
                            ])
                            
                            menuSection(title: "Legal", items: [
                                ("doc.text", "Terms of Service", ProfileRoute.termsOfService),
                                ("shield", "Privacy Policy", ProfileRoute.privacyPolicy)
                            ])

                            // MARK: Logout Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Account Actions")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.lmTextSecondary.opacity(0.6))
                                    .padding(.horizontal, 8)
                                
                                Button(action: {
                                    // Removing withAnimation here as it can cause a 
                                    // crash during the root view swap in SwiftUI 4/5. 
                                    // The RootView handles the transition animation.
                                    isLoggedIn = false
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.system(size: 18))
                                            .foregroundColor(.red)
                                            .frame(width: 24)
                                        
                                        Text("Logout")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.red)
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                                    .background(Color.red.opacity(0.05))
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.red.opacity(0.1), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 150)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.lmPrimary)
                    .frame(width: 96, height: 96)
                    .overlay(
                        Text("EJ")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                // Camera Badge
                Circle()
                    .fill(Color.white)
                    .frame(width: 28, height: 28)
                    .shadow(radius: 2)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.lmPrimary)
                    )
                    .offset(x: -4, y: -4)
            }
            
            VStack(spacing: 4) {
                Text("Emily Johnson")
                    .font(.lmHeading)
                    .foregroundColor(.lmPrimary)
                
                Text("emily.johnson@email.com")
                    .font(.lmCaption)
                    .foregroundColor(.lmTextSecondary)
            }
            
            Text("Member since January 2024")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.lmTextSecondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.lmPrimary.opacity(0.1))
                .clipShape(Capsule())
        }
    }
    
    // MARK: - Menu Section
    private func menuSection(title: String, items: [(String, String, ProfileRoute)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.lmTextSecondary.opacity(0.6))
                .padding(.horizontal, 8)
            
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    NavigationLink(value: item.2) {
                        HStack(spacing: 16) {
                            Image(systemName: item.0)
                                .font(.system(size: 18))
                                .foregroundColor(.lmPrimary)
                                .frame(width: 24)
                            
                            Text(item.1)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.lmTextPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.gray.opacity(0.4))
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(Color.white)
                    }
                    .buttonStyle(.plain)
                    
                    if index < items.count - 1 {
                        Divider()
                            .padding(.leading, 60)
                            .padding(.trailing, 20)
                    }
                }
            }
            .background(Color.white.opacity(0.6))
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    ProfileView()
}
