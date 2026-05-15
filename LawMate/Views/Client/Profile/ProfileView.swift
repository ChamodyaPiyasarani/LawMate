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
    case accessibility
}

struct ProfileView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @AppStorage("userRole") private var userRole: UserRole = .client
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var auth: AuthService
    
    // Photo Selection State
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showSourceSelection = false
    @State private var isUploading = false
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @Binding var navPath: NavigationPath
    @Binding var activeConversation: FBConversation?
    
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
                    
                    NotificationButton()
                        .padding(6)
                        .background(Circle().fill(Color.white.opacity(0.9)))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.top, 65)
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
                                ("bell", "Notifications", ProfileRoute.profileNotifications),
                                ("accessibility", "Accessibility", ProfileRoute.accessibility)
                            ])
                            
                            menuSection(title: "Legal", items: [
                                ("doc.text", "Terms of Service", ProfileRoute.termsOfService),
                                ("shield", "Privacy Policy", ProfileRoute.privacyPolicy)
                            ])

                            // MARK: Account Actions Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Account Actions")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.lmTextSecondary.opacity(0.6))
                                    .padding(.horizontal, 8)
                                
                                VStack(spacing: 0) {
                                    Button(action: {
                                        showLogoutAlert = true
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
                                        .background(Color.white.opacity(0.6))
                                        .background(.ultraThinMaterial)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Divider().padding(.horizontal, 20)
                                    
                                    Button(action: {
                                        showDeleteAlert = true
                                    }) {
                                        HStack(spacing: 16) {
                                            Image(systemName: "person.badge.minus")
                                                .font(.system(size: 18))
                                                .foregroundColor(.red)
                                                .frame(width: 24)
                                            
                                            Text("Delete Account")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.red)
                                            
                                            Spacer()
                                            
                                            if isDeleting {
                                                ProgressView().tint(.red)
                                            }
                                        }
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 20)
                                        .background(Color.white.opacity(0.6))
                                        .background(.ultraThinMaterial)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isDeleting)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.red.opacity(0.1), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 150)
                }
            }
            
        }
        .ignoresSafeArea(edges: .top)
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
        .onChange(of: selectedImage) { _, newImage in
            if let img = newImage {
                uploadImage(img)
            }
        }

        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Logout", role: .destructive) {
                auth.logout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Delete Permanently", role: .destructive) {
                performDeleteAccount()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action is permanent and cannot be undone. All your data, cases, and messages will be lost.")
        }
    }
    
    private func performDeleteAccount() {
        isDeleting = true
        auth.deleteAccount { result in
            DispatchQueue.main.async {
                isDeleting = false
                switch result {
                case .success:
                    ToastManager.shared.show(title: "Account Deleted", message: "Your data has been removed.", type: .success)
                case .failure(let error):
                    ToastManager.shared.show(title: "Deletion Failed", message: error.localizedDescription, type: .error)
                }
            }
        }
    }
    
    private func uploadImage(_ image: UIImage) {
        isUploading = true
        auth.uploadProfileImage(image) { result in
            DispatchQueue.main.async {
                isUploading = false
                switch result {
                case .success:
                    ToastManager.shared.show(title: "Success", message: "Profile picture updated.", type: .success)
                case .failure(let error):
                    ToastManager.shared.show(title: "Error", message: error.localizedDescription, type: .error)
                }
            }
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
                        if isUploading {
                            ProgressView()
                                .frame(width: 96, height: 96)
                                .background(Color.lmPrimary.opacity(0.1))
                                .clipShape(Circle())
                        } else {
                            LawMateAvatar(
                                url: auth.currentUser?.profileImage,
                                name: auth.currentUser?.fullName ?? "User",
                                size: 96
                            )
                        }
                    }
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
                Text(auth.currentUser?.fullName ?? (userRole == .lawyer ? "Nimal Perera" : "Emily Johnson"))
                    .font(.lmHeading)
                    .foregroundColor(.lmPrimary)
                
                Text(auth.currentUser?.email ?? (userRole == .lawyer ? "perera.nimal@lawmate.com" : "emily.johnson@email.com"))
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
    
    // MARK: - Helpers
    private func initials(for name: String?) -> String? {
        guard let name = name, !name.isEmpty else { return nil }
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
}

#Preview {
    ProfileView(navPath: .constant(NavigationPath()), activeConversation: .constant(nil))
}
