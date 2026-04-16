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

struct RootView: View {
    @StateObject private var auth = AuthService.shared
    @State private var showSplash = true
    @State private var showSeedAlert = false

    var body: some View {
        Group {
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
                    .overlay(alignment: .bottom) {
                        Button("Developer: Seed Data") {
                            FirestoreManager.shared.seedInitialLawyers()
                            showSeedAlert = true
                        }
                        .font(.lmCaption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                    }
                    .alert("Database Seeded", isPresented: $showSeedAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("Mock lawyers have been added to your Firestore. You can now login or sign up.")
                    }
            }
        }
    }
}

#Preview {
    RootView()
}
