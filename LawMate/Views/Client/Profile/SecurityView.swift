import SwiftUI

struct SecurityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            GreenBlobBackground(style: .client).frame(height: 300)
            
            VStack(spacing: 0) {
                LawMateNavigationBar(title: "Security", showBack: true, onBack: { dismiss() })
                    .padding(.top, 64)
                    .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        ProfileInputRow(icon: "lock.fill", title: "Current Password", text: $currentPassword)
                        ProfileInputRow(icon: "key.fill", title: "New Password", text: $newPassword)
                        ProfileInputRow(icon: "checkmark.shield.fill", title: "Confirm Password", text: $confirmPassword)
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Update Password")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.lmPrimary)
                                .clipShape(Capsule())
                        }
                        .padding(.top, 24)
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
    SecurityView()
}
