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
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var acc: AccessibilityManager
    @State private var showSplash = true

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                // Main app content
                mainContent
            }
            .dynamicTypeSize(acc.dynamicTypeSize)
            .id(acc.highContrast) // Forces redraw when colors change
            
            ToastView()
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
}

#Preview {
    RootView()
}
