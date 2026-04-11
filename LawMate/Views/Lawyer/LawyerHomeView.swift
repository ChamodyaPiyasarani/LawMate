import SwiftUI

struct LawyerHomeView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @AppStorage("userRole") private var storedRole: UserRole = .lawyer

    var body: some View {
        ZStack {
            Color.lmBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                LawMateLogoView(style: .compact)
                    .padding(.top, 40)
                
                Spacer()
                
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.lmPrimary)
                
                Text("Welcome, Lawyer!")
                    .font(.lmTitle)
                    .foregroundColor(.lmPrimary)
                
                Text("The Lawyer Dashboard is currently under development.")
                    .font(.lmBody)
                    .foregroundColor(.lmTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                LawMateSecondaryButton(title: "Logout") {
                    withAnimation {
                        isLoggedIn = false
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
    }
}

#Preview {
    LawyerHomeView()
}
