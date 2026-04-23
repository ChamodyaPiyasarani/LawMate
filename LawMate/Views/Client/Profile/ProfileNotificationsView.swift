import SwiftUI

struct ProfileNotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("pushEnabled") private var pushEnabled = true
    @AppStorage("emailEnabled") private var emailEnabled = true
    @AppStorage("updatesEnabled") private var updatesEnabled = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            GreenBlobBackground(style: .client).frame(height: 300)
            
            VStack(spacing: 0) {
                LawMateNavigationBar(title: "Notifications", showBack: true, onBack: { dismiss() })
                    .padding(.top, 64)
                    .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(spacing: 0) {
                            ToggleRow(title: "Push Notifications", icon: "bell.badge.fill", isOn: $pushEnabled)
                            Divider().padding(.leading, 60).padding(.trailing, 20)
                            ToggleRow(title: "Email Notifications", icon: "envelope.fill", isOn: $emailEnabled)
                            Divider().padding(.leading, 60).padding(.trailing, 20)
                            ToggleRow(title: "App Updates & News", icon: "megaphone.fill", isOn: $updatesEnabled)
                        }
                        .background(Color.white.opacity(0.8))
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ProfileNotificationsView()
}
