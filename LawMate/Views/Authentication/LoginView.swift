//
//  LoginView.swift
//  LawMate
//
//  Created by COBSCCOMP242P-030 on 2026-04-07.
//
//  Screen 3 — Login
//  Green blob header, email + password fields, login CTA,
//  sign-up link, and biometric auth option.
//

import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userRole") private var storedRole: UserRole = .client
    @AppStorage("biometricsEnabled") private var biometricsEnabled = false
    @State private var email:    String = ""
    @State private var password: String = ""
    @State private var navigateToSignUp   = false
    @State private var biometricError: String? = nil
    
    // Validation Errors
    @State private var emailError: String?
    @State private var passwordError: String?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.lmBackground.ignoresSafeArea()

                // Green blob top-left
                GreenBlobBackground()
                    .frame(height: 260)

                VStack(spacing: 0) {
                    // MARK: Fixed Header area
                    HStack {
                        LawMateLogoView(style: .compact)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 65)
                    .padding(.bottom, 10)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {

                            // MARK: Title
                            Text("Login")
                                .font(.lmTitle)
                                .foregroundColor(.lmPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                                .padding(.bottom, 50)

                            // MARK: Form fields
                            VStack(spacing: 20) {
                                LawMateTextField(icon: "at",
                                                placeholder: "Email Address",
                                                text: $email,
                                                keyboardType: .emailAddress,
                                                errorMessage: emailError)

                                LawMateTextField(icon: "lock",
                                                placeholder: "Password",
                                                text: $password,
                                                isSecure: true,
                                                errorMessage: passwordError)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 36)

                            LawMatePrimaryButton(title: "Sign in") {
                                if validateForm() {
                                    ToastManager.shared.show(title: "Logging in...", message: "Please wait.", type: .info)
                                    
                                    AuthService.shared.login(email: email, password: password) { result in
                                        DispatchQueue.main.async {
                                            switch result {
                                            case .success:
                                                // 1. Always update stored credentials on success
                                                KeychainManager.shared.saveCredentials(email: email, password: password)
                                                
                                                // 2. Show success message
                                                ToastManager.shared.show(title: "Welcome Back!", message: "Successfully logged in.", type: .success)
                                                
                                                // 3. Trigger biometric opt-in logic if not enabled
                                                if !biometricsEnabled {
                                                    UserDefaults.standard.set(true, forKey: "shouldShowBiometricPrompt")
                                                }
                                            case .failure(let error):
                                                ToastManager.shared.show(title: "Login Failed", message: error.localizedDescription, type: .error)
                                            }
                                        }
                                    }
                                } else {
                                    ToastManager.shared.show(title: "Validation Error", message: "Please check your login details.", type: .error)
                                }
                            }
                            .padding(.horizontal, 40)

                            // MARK: Sign Up link
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .font(.lmCaption)
                                    .foregroundColor(.lmTextSecondary)
                                Button {
                                    navigateToSignUp = true
                                } label: {
                                    Text("Sign Up here!")
                                        .font(.lmCaption.weight(.semibold))
                                        .foregroundColor(.lmPrimary)
                                        .underline()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)

                            // MARK: Divider
                            HStack(spacing: 12) {
                                Rectangle()
                                    .fill(Color.lmBorder.opacity(0.5))
                                    .frame(height: 1)
                                Text("Or continue with")
                                    .font(.lmCaption)
                                    .foregroundColor(.lmTextSecondary)
                                    .fixedSize()
                                Rectangle()
                                    .fill(Color.lmBorder.opacity(0.5))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 40)

                            // MARK: Biometric button (centered & compact)
                            HStack {
                                Spacer()
                                LawMateSecondaryButton(
                                    title: "Biometric Login",
                                    icon: biometricIcon,
                                    titleColor: .lmTextSecondary,
                                    iconColor: .lmTextSecondary,
                                    font: .lmCaption
                                ) {
                                    authenticateWithBiometrics()
                                }
                                Spacer()
                            }
                            .padding(.top, 20)

                            if let error = biometricError {
                                Text(error)
                                    .font(.lmCaption)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 8)
                                    .padding(.horizontal, 24)
                            }
                        }
                    }

                    // MARK: Fixed Footer
                    LawMateFooter()
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToSignUp) {
                SignUpView()
            }
        }
    }

    // MARK: - Biometric icon
    private var biometricIcon: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType == .faceID ? "faceid" : "touchid"
    }

    private func authenticateWithBiometrics() {
        guard biometricsEnabled else {
            ToastManager.shared.show(title: "Not Enabled", message: "Please log in manually first to enable biometrics.", type: .warning)
            return
        }
        
        let credentials = KeychainManager.shared.getCredentials()
        guard let savedEmail = credentials.email, let savedPassword = credentials.password else {
            ToastManager.shared.show(title: "Credentials Missing", message: "Please log in manually to refresh your session.", type: .error)
            biometricsEnabled = false
            return
        }
        
        AuthService.shared.authenticateWithBiometrics { success, error in
            if success {
                ToastManager.shared.show(title: "Biometrics Matched", message: "Logging you in...", type: .info)
                
                AuthService.shared.login(email: savedEmail, password: savedPassword) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            ToastManager.shared.show(title: "Welcome Back!", message: "Successfully logged in.", type: .success)
                            NotificationManager.shared.scheduleNotification(
                                title: "Login Successful",
                                body: "Welcome back to LawMate."
                            )
                        case .failure(let error):
                            biometricError = "Auto-login failed: \(error.localizedDescription)"
                            ToastManager.shared.show(title: "Login Failed", message: "Credentials may be outdated. Please log in manually.", type: .error)
                        }
                    }
                }
            } else {
                biometricError = error ?? "Biometric authentication failed."
            }
        }
    }
    

    private func validateForm() -> Bool {
        var isValid = true
        
        emailError = (email.isEmpty || !email.contains("@")) ? "Enter a valid email address" : nil
        if emailError != nil { isValid = false }
        
        passwordError = password.isEmpty ? "Password cannot be empty" : nil
        if passwordError != nil { isValid = false }
        
        return isValid
    }
}

#Preview {
    LoginView()
}
