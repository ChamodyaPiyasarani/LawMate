import SwiftUI

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            GreenBlobBackground(style: .client).frame(height: 300)
            
            VStack(spacing: 0) {
                LawMateNavigationBar(title: "Privacy Policy", showBack: true, onBack: { dismiss() })
                    .padding(.top, 54)
                    .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Effective Date: January 15, 2026")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.lmTextSecondary)
                        
                        Text("Information We Collect")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.lmPrimary)
                        Text("We collect personal information such as your name, email, phone number, and biometrics (where enabled) solely to verify your identity and provide tailored legal services. Payment information is securely handled by our third-party processors.")
                            .font(.system(size: 14))
                            .foregroundColor(.lmTextPrimary)
                            .lineSpacing(6)
                        
                        Text("How We Use Information")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.lmPrimary)
                        Text("Your data is strictly used to pair you with qualified legal representatives, verify conflict-of-interest checks, and securely host matched cases. We will never sell your information to advertisers.")
                            .font(.system(size: 14))
                            .foregroundColor(.lmTextPrimary)
                            .lineSpacing(6)
                            
                        Text("Data Retention")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.lmPrimary)
                        Text("We retain your case data for up to 7 years in compliance with legal industry documentation regulations, unless you request a formal account deletion along with your lawyer's consent.")
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
    PrivacyView()
}
