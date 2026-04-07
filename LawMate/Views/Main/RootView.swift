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
    var body: some View {
        SplashView()
    }
}

#Preview {
    RootView()
}
