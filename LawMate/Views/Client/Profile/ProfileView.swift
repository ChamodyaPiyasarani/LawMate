import SwiftUI
import UIKit

enum ProfileRoute: Hashable {
    case personalInfo
    case security
    case biometrics
    case profileNotifications
    case termsOfService
    case privacyPolicy
    case myUploads
}

struct ProfileView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @AppStorage("userRole") private var userRole: UserRole = .client
    @Environment(\.dismiss) private var dismiss
    
    // Photo Selection State
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showSourceSelection = false
    
    var onBack: () -> Void = {}
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Background Blob (Style based on role)
            GreenBlobBackground(style: userRole == .lawyer ? .lawyer : .client)
                .frame(height: 300)
            
            VStack(spacing: 0) {
                // MARK: Left-Aligned Header
                HStack(alignment: .center) {
                    Text("Profile")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    Spacer()
                    
                    NotificationButton(badgeCount: 3, action: {})
                }
                .padding(.horizontal, 24)
                .padding(.top, 64)
                .padding(.bottom, 24)
                .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // MARK: Profile Info
                        profileHeader
                        
                        VStack(spacing: 24) {
                            // MARK: Account Section
                            menuSection(title: "Account", items: accountItems)
                            
                            // MARK: Other Sections
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
        .navigationBarBackButtonHidden(true)
        .confirmationDialog("Change Profile Photo", isPresented: $showSourceSelection) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") {
                    imageSource = .camera
                    showImagePicker = true
                }
            }
            
            Button("Choose from Library") {
                imageSource = .photoLibrary
                showImagePicker = true
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: imageSource, selectedImage: $selectedImage)
        }
    }
    
    private var accountItems: [(String, String, ProfileRoute)] {
        var items = [
            ("person", "Personal Information", ProfileRoute.personalInfo),
            ("lock", "Security & Password", ProfileRoute.security),
            ("faceid", "Biometric Settings", ProfileRoute.biometrics)
        ]
        
        if userRole == .lawyer {
            items.append(("doc.text", "My Advisory Documents", ProfileRoute.myUploads))
        }
        
        return items
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            Button {
                showSourceSelection = true
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Circle()
                                .fill(Color.lmPrimary)
                                .overlay(
                                    Text(userRole == .lawyer ? "NP" : "EJ")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    .frame(width: 96, height: 96)
                    .clipShape(Circle())
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
            }
            .buttonStyle(.plain)
            
            VStack(spacing: 4) {
                Text(userRole == .lawyer ? "Nimal Perera" : "Emily Johnson")
                    .font(.lmHeading)
                    .foregroundColor(.lmPrimary)
                
                Text(userRole == .lawyer ? "perera.nimal@lawmate.com" : "emily.johnson@email.com")
                    .font(.lmCaption)
                    .foregroundColor(.lmTextSecondary)
            }
            
            Text(userRole == .lawyer ? "Lawyer since March 2020" : "Member since January 2024")
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
