import SwiftUI

struct TermsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            GreenBlobBackground(style: .client).frame(height: 300)
            
            VStack(spacing: 0) {
                LawMateNavigationBar(title: "Terms of Service", showBack: true, onBack: { dismiss() })
                    .padding(.top, 64)
                    .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Last Updated: January 15, 2026")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.lmTextSecondary)
                        
                        Text("1. Acceptance of Terms")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.lmPrimary)
                        Text("By accessing and using LawMate, you agree to comply with and be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.")
                            .font(.system(size: 14))
                            .foregroundColor(.lmTextPrimary)
                            .lineSpacing(6)
                        
                        Text("2. Use of Services")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.lmPrimary)
                        Text("LawMate provides a platform to connect clients with legal professionals. We DO NOT directly provide legal counsel, and the communication facilitated by this app does not instantly substitute a formal attorney-client contract outside the parameters defined by the matched legal expert.")
                            .font(.system(size: 14))
                            .foregroundColor(.lmTextPrimary)
                            .lineSpacing(6)
                            
                        Text("3. Privacy & Data")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.lmPrimary)
                        Text("We take your security seriously and utilize end-to-end encryption for document transfers. However, you acknowledge that you are responsible for any sensitive information manually shared.")
                            .font(.system(size: 14))
                            .foregroundColor(.lmTextPrimary)
                            .lineSpacing(6)
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.8))
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 100)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    TermsView()
}
