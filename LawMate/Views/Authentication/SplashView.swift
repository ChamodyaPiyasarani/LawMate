//
//  SplashView.swift
//  LawMate
//
//  Created by COBSCCOMP242P-030 on 2026-04-07.
//
//  Screen 1 — Splash Screen
//  White background with centered brand logo, auto-navigates after 2.5s.
//

import SwiftUI

struct SplashView: View {
    var onComplete: () -> Void = {}
    
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var isActive: Bool = false

    var body: some View {
        splashContent
            .onAppear { startAnimation() }
            .onChange(of: isActive) { oldValue, newValue in
                if newValue { onComplete() }
            }
    }

    private var splashContent: some View {
        ZStack {
            // Pure white background
            Color.lmBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 20) {
                    AppLogoView(size: 200)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                    VStack(spacing: 6) {
                        Text("Legal & Professional Assistant")
                            .font(.lmBody)
                            .foregroundColor(.lmAccent)

                        Text("LAWMATE")
                            .font(Font.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundColor(.lmPrimary)
                            .tracking(3)
                    }
                    .opacity(textOpacity)
                }

                Spacer()

                // Footer
                LawMateFooter()
                    .padding(.bottom, 10)
                    .opacity(textOpacity)
            }
        }
    }

    // MARK: - Animation sequence
    private func startAnimation() {
        // Logo zoom in
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        // Text fade in
        withAnimation(.easeIn(duration: 0.6).delay(0.4)) {
            textOpacity = 1.0
        }
        // Navigate after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.4)) {
                isActive = true
            }
        }
    }
}

#Preview {
    SplashView()
}
