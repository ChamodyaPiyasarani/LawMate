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
    @State private var email:    String = ""
    @State private var password: String = ""
    @State private var navigateToSignUp   = false
    @State private var biometricError: String? = nil

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
                    .padding(.top, 54)
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
                                                keyboardType: .emailAddress)

                                LawMateTextField(icon: "lock",
                                                placeholder: "Password",
                                                text: $password,
                                                isSecure: true)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 36)

                            // MARK: Sign In button
                            LawMatePrimaryButton(title: "Sign in") {
                                withAnimation {
                                    isLoggedIn = true
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

    // MARK: - Biometric auth (UI stub — no real auth logic yet)
    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricError = "Biometrics not available on this device."
            return
        }
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Login to LawMate"
        ) { success, _ in
            DispatchQueue.main.async {
                if success {
                    withAnimation {
                        isLoggedIn = true
                    }
                } else {
                    biometricError = "Biometric authentication failed."
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
