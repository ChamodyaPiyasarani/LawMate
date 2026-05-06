import SwiftUI

struct SecurityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isUpdating = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            GreenBlobBackground(style: .client).frame(height: 300)
            
            VStack(spacing: 0) {
                LawMateNavigationBar(title: "Security", showBack: true, onBack: { dismiss() })
                    .padding(.top, 54)
                    .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        ProfileInputRow(icon: "lock.fill", title: "Current Password", text: $currentPassword)
                        ProfileInputRow(icon: "key.fill", title: "New Password", text: $newPassword)
                        ProfileInputRow(icon: "checkmark.shield.fill", title: "Confirm Password", text: $confirmPassword)
                        
                        Button {
                            guard !newPassword.isEmpty else {
                                ToastManager.shared.show(title: "Error", message: "Password cannot be empty.", type: .error)
                                return
                            }
                            guard newPassword == confirmPassword else {
                                ToastManager.shared.show(title: "Mismatch", message: "Passwords do not match.", type: .error)
                                return
                            }
                            
                            isUpdating = true
                            AuthService.shared.updatePassword(newPassword: newPassword) { result in
                                DispatchQueue.main.async {
                                    isUpdating = false
                                    switch result {
                                    case .success:
                                        ToastManager.shared.show(title: "Success", message: "Password updated successfully.", type: .success)
                                        dismiss()
                                    case .failure(let error):
                                        ToastManager.shared.show(title: "Update Failed", message: error.localizedDescription, type: .error)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                if isUpdating {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Update Password")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.lmPrimary)
                                .clipShape(Capsule())
                        }
                        .disabled(isUpdating)
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
