//
//  RootView.swift
//  LawMate
//
//  Created by COBSCCOMP242P-030 on 2026-04-07.
//
//  Root router — decides which screen to show.
//  Currently always shows SplashView (which auto-navigates to Login).
//  In future, this can check auth state and jump to HomeView directly.
//

import SwiftUI
import LocalAuthentication

struct RootView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var acc: AccessibilityManager
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @AppStorage("biometricsEnabled") private var biometricsEnabled = false
    @State private var showSplash = true
    @State private var isLocked = false
    @State private var isUnlocking = false
    @State private var unlockError: String? = nil
    @State private var lastUnlockAt: Date? = nil

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                // Main app content
                mainContent
            }
            .dynamicTypeSize(acc.dynamicTypeSize)
            .environment(\.legibilityWeight, acc.effectiveHighContrast ? .bold : .regular)
            .id(acc.effectiveHighContrast) // Forces redraw when colors change
            
            ToastView()
            if shouldShowLock {
                appLockOverlay
            }
        }
        .onAppear {
            updateLockState(reason: "App launch")
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                updateLockState(reason: "App became active")
            }
        }
        .onChange(of: auth.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                updateLockState(reason: "User authenticated")
            } else {
                isLocked = false
                unlockError = nil
                isUnlocking = false
            }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if showSplash {
            SplashView(onComplete: {
                withAnimation { showSplash = false }
            })
        } else if auth.isAuthenticated {
            if auth.currentUser?.role == .lawyer {
                LawyerHomeView()
            } else {
                ClientHomeView()
            }
        } else {
            LoginView()
        }
    }

    private var shouldShowLock: Bool {
        auth.isAuthenticated && appLockEnabled && isLocked
    }

    private var appLockOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 12) {
                Text("App Locked")
                    .font(.lmHeading)
                    .foregroundColor(.white)
                Text("Unlock using Face ID / Touch ID")
                    .font(.lmCaption)
                    .foregroundColor(.white.opacity(0.85))
                if let error = unlockError {
                    Text(error)
                        .font(.lmCaption)
                        .foregroundColor(.red.opacity(0.9))
                }
                Button {
                    unlockApp()
                } label: {
                    HStack {
                        if isUnlocking {
                            ProgressView().tint(.white)
                        } else {
                            Text("Unlock")
                                .font(.lmButton)
                        }
                    }
                    .frame(maxWidth: 200)
                    .padding(.vertical, 12)
                    .background(Color.lmPrimary)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                .disabled(isUnlocking)
                .buttonStyle(.plain)
            }
            .padding(24)
            .background(Color.black.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    private func updateLockState(reason: String) {
        guard auth.isAuthenticated, appLockEnabled else {
            isLocked = false
            return
        }
        if !biometricsEnabled {
            appLockEnabled = false
            isLocked = false
            unlockError = "Biometrics must be enabled to use app lock."
            return
        }
        if let lastUnlockAt, Date().timeIntervalSince(lastUnlockAt) < 1.5 {
            return
        }
        isLocked = true
    }

    private func unlockApp() {
        guard biometricsEnabled else {
            unlockError = "Biometrics are disabled."
            return
        }
        isUnlocking = true
        unlockError = nil
        AuthService.shared.authenticateWithBiometrics { success, error in
            isUnlocking = false
            if success {
                lastUnlockAt = Date()
                isLocked = false
                unlockError = nil
            } else {
                unlockError = error ?? "Authentication failed."
            }
        }
    }
}

#Preview {
    RootView()
}
