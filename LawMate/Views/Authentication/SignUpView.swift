import SwiftUI
import CoreLocation

struct SignUpView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userRole") private var storedRole: UserRole = .none
    @Environment(\.dismiss) private var dismiss

    @State private var username:  String = ""
    @State private var email:     String = ""
    @State private var contact:   String = ""
    @State private var address:   String = ""
    @State private var password:  String = ""
    @State private var role:      UserRole = .none
    
    // Lawyer specific fields
    @State private var experience: String = ""
    @State private var specialty:  String = ""
    @State private var bio:        String = ""
    @State private var casesWon:   String = ""

    @State private var navigateToLogin = false
    
    // Validation Errors
    @State private var usernameError: String?
    @State private var emailError: String?
    @State private var contactError: String?
    @State private var addressError: String?
    @State private var passwordError: String?
    @State private var experienceError: String?
    
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
                                                text: $username,
                                                errorMessage: usernameError)

                                LawMateTextField(icon: "at",
                                                placeholder: "Email Address",
                                                text: $email,
                                                keyboardType: .emailAddress,
                                                errorMessage: emailError)

                                LawMateTextField(icon: "phone",
                                                placeholder: "Contact Number",
                                                text: $contact,
                                                keyboardType: .phonePad,
                                                errorMessage: contactError)

                                LawMateTextField(icon: "mappin.and.ellipse",
                                                placeholder: "Address",
                                                text: $address,
                                                errorMessage: addressError)
                            }
                            .padding(.horizontal, 24)

                            // MARK: Role selection
                            VStack(alignment: .leading, spacing: 16) {
                                Text("I Am A. . . .")
                                    .font(.lmBody)
                                    .foregroundColor(.lmTextSecondary)

                                HStack(spacing: 16) {
                                    RoleButton(title: "Lawyer",
                                               icon: "briefcase",
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
                                    LawMateTextField(icon: "star",
                                                    placeholder: "Years of Experience",
                                                    text: $experience,
                                                    keyboardType: .numberPad,
                                                    errorMessage: experienceError)
                                    
                                    // Specialized Field Dropdown
                                    Menu {
                                        ForEach(specialties, id: \.self) { spec in
                                            Button(spec) {
                                                specialty = spec
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "briefcase")
                                                .foregroundColor(.lmTextSecondary)
                                                .frame(width: 24)
                                            
                                            Text(specialty.isEmpty ? "Specialized Field (e.g. Divorce)" : specialty)
                                                .foregroundColor(specialty.isEmpty ? .lmTextSecondary : .lmTextPrimary)
                                                .font(.lmBody)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.lmTextSecondary)
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
                                    
                                    LawMateTextField(icon: "trophy",
                                                    placeholder: "Cases Won (e.g. 100+)",
                                                    text: $casesWon)
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 24)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            // MARK: Password field
                            LawMateTextField(icon: "lock",
                                            placeholder: "Password",
                                            text: $password,
                                            isSecure: true,
                                            errorMessage: passwordError)
                                .padding(.horizontal, 24)
                                .padding(.top, 24)

                            LawMatePrimaryButton(title: "Sign up") {
                                if validateForm() {
                                    ToastManager.shared.show(title: "Creating account...", message: "Please wait.", type: .info)
                                    
                                    // Geocode address first
                                    geocodeAddress(address) { coordinate in
                                        var profileData: [String: Any] = [
                                            "fullName": username,
                                            "phone": contact,
                                            "specialty": specialty,
                                            "experience": experience,
                                            "bio": bio,
                                            "casesWon": casesWon,
                                            "address": address
                                        ]
                                        
                                        if let coord = coordinate {
                                            profileData["latitude"] = coord.latitude
                                            profileData["longitude"] = coord.longitude
                                        }
                                        
                                        AuthService.shared.signUp(email: email, role: role, password: password, profile: profileData) { result in
                                            switch result {
                                            case .success:
                                                ToastManager.shared.show(title: "Success", message: "Account created successfully!", type: .success)
                                                NotificationManager.shared.scheduleNotification(
                                                    title: "Welcome to LawMate!",
                                                    body: "Your account has been registered successfully."
                                                )
                                            case .failure(let error):
                                                ToastManager.shared.show(title: "Registration Failed", message: error.localizedDescription, type: .error)
                                            }
                                        }
                                    }
                                } else {
                                    ToastManager.shared.show(title: "Validation Error", message: "Please check the form for errors.", type: .error)
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
    private func validateForm() -> Bool {
        var isValid = true
        
        usernameError = username.isEmpty ? "Username cannot be empty" : nil
        if usernameError != nil { isValid = false }
        
        emailError = (email.isEmpty || !email.contains("@")) ? "Enter a valid email address" : nil
        if emailError != nil { isValid = false }
        
        contactError = contact.count < 10 ? "Enter a valid phone number" : nil
        if contactError != nil { isValid = false }
        
        addressError = address.isEmpty ? "Address cannot be empty" : nil
        if addressError != nil { isValid = false }
        
        passwordError = password.count < 6 ? "Password must be at least 6 characters" : nil
        if passwordError != nil { isValid = false }
        
        if role == .none {
            ToastManager.shared.show(title: "Select Role", message: "Please select whether you are a Lawyer or Client", type: .warning)
            isValid = false
        }
        
        if role == .lawyer {
            experienceError = experience.isEmpty ? "Experience required" : nil
            if experienceError != nil { isValid = false }
        }
        
        return isValid
    }

    private func geocodeAddress(_ address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            completion(placemarks?.first?.location?.coordinate)
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
