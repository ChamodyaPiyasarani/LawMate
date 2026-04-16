import SwiftUI

struct SignUpView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userRole") private var storedRole: UserRole = .none
    @Environment(\.dismiss) private var dismiss

    @State private var username:  String = ""
    @State private var email:     String = ""
    @State private var contact:   String = ""
    @State private var password:  String = ""
    @State private var role:      UserRole = .none
    
    // Lawyer specific fields
    @State private var experience: String = ""
    @State private var specialty:  String = ""
    @State private var bio:        String = ""

    @State private var navigateToLogin = false
    
    let specialties = ["Criminal Law", "Family Law", "Corporate Law", "Property Law", "Civil Law", "Others"]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.lmBackground.ignoresSafeArea()

                // Green blob at top-left
                GreenBlobBackground()
                    .frame(height: 260)

                VStack(spacing: 0) {
                    // MARK: Fixed Header area
                    HStack {
                        LawMateLogoView(style: .compact)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 54)
                    .padding(.bottom, 10)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {

                            // MARK: Title
                            Text("Sign UP")
                                .font(.lmTitle)
                                .foregroundColor(.lmPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 30)
                                .padding(.bottom, 40)

                            // MARK: Form fields
                            VStack(spacing: 20) {
                                LawMateTextField(icon: "person",
                                                placeholder: "User Name",
                                                text: $username)

                                LawMateTextField(icon: "at",
                                                placeholder: "Email Address",
                                                text: $email,
                                                keyboardType: .emailAddress)

                                LawMateTextField(icon: "phone",
                                                placeholder: "Contact Number",
                                                text: $contact,
                                                keyboardType: .phonePad)
                            }
                            .padding(.horizontal, 24)

                            // MARK: Role selection
                            VStack(alignment: .leading, spacing: 16) {
                                Text("I Am A. . . .")
                                    .font(.lmBody)
                                    .foregroundColor(.lmTextSecondary)

                                HStack(spacing: 16) {
                                    RoleButton(title: "Lawyer",
                                               icon: "briefcase.fill",
                                               isSystemIcon: true,
                                               isSelected: role == .lawyer) {
                                        role = (role == .lawyer) ? .none : .lawyer
                                    }
                                    RoleButton(title: "Client",
                                               icon: "person",
                                               isSystemIcon: true,
                                               isSelected: role == .client) {
                                        role = (role == .client) ? .none : .client
                                    }
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 32)
                            
                            // MARK: Conditional Lawyer Fields
                            if role == .lawyer {
                                VStack(spacing: 20) {
                                    LawMateTextField(icon: "star.fill",
                                                    placeholder: "Years of Experience",
                                                    text: $experience,
                                                    keyboardType: .numberPad)
                                    
                                    // Specialized Field Dropdown
                                    Menu {
                                        ForEach(specialties, id: \.self) { spec in
                                            Button(spec) {
                                                specialty = spec
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "briefcase.fill")
                                                .foregroundColor(.lmPrimary)
                                                .frame(width: 24)
                                            
                                            Text(specialty.isEmpty ? "Specialized Field (e.g. Divorce)" : specialty)
                                                .foregroundColor(specialty.isEmpty ? .lmTextSecondary : .lmTextPrimary)
                                                .font(.lmBody)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.lmPrimary)
                                        }
                                        .padding()
                                        .background(Color.white.opacity(0.6))
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    
                                    LawMateTextField(icon: "pencil",
                                                    placeholder: "Small Description",
                                                    text: $bio)
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 24)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            // MARK: Password field
                            LawMateTextField(icon: "lock",
                                            placeholder: "Password",
                                            text: $password,
                                            isSecure: true)
                                .padding(.horizontal, 24)
                                .padding(.top, 24)

                            LawMatePrimaryButton(title: "Sign up") {
                                if role != .none {
                                    let profileData: [String: String] = [
                                        "fullName": username,
                                        "phone": contact,
                                        "specialty": specialty,
                                        "experience": experience,
                                        "bio": bio
                                    ]
                                    
                                    AuthService.shared.login(email: email, role: role, profile: profileData)
                                    // The observer in AuthService will toggle isLoggedIn automatically
                                    NotificationManager.shared.scheduleNotification(
                                        title: "Welcome to LawMate!",
                                        body: "Your account is registering..."
                                    )
                                }
                            }
                            .padding(.horizontal, 40)
                            .padding(.top, 40)

                            // MARK: Login link
                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .font(.lmCaption)
                                    .foregroundColor(.lmTextSecondary)
                                Button {
                                    navigateToLogin = true
                                } label: {
                                    Text("Login here!")
                                        .font(.lmCaption.weight(.semibold))
                                        .foregroundColor(.lmPrimary)
                                        .underline()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                        }
                    }

                    // MARK: Fixed Footer
                    LawMateFooter()
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginView()
            }
        }
    }
}

// MARK: - Role selector pill button
struct RoleButton: View {
    let title: String
    let icon: String
    var isSystemIcon: Bool = true
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSystemIcon {
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .frame(width: 18) // Ensure consistent width
                } else {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                }
                Text(title)
                    .font(.lmBody)
            }
            .foregroundColor(isSelected ? .white : .lmTextSecondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(isSelected ? Color.lmPrimary : Color.clear)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SignUpView()
}
