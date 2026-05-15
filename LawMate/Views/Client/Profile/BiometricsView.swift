import SwiftUI
import LocalAuthentication

struct BiometricsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("biometricsEnabled") private var biometricsEnabled = false
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            GreenBlobBackground(style: .client).frame(height: 300)
            
            VStack(spacing: 0) {
                LawMateNavigationBar(title: "Biometrics", showBack: true, onBack: { dismiss() })
                    .padding(.top, 65)
                    .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Image(systemName: "faceid")
                            .font(.system(size: 64))
                            .foregroundColor(.lmPrimary)
                            .padding(.vertical, 20)
                            
                        Text("Secure your account with Face ID / Touch ID for quick and easy access.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.lmTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            ToggleRow(title: "Use Biometrics", icon: "faceid", isOn: $biometricsEnabled)
                                .onChange(of: biometricsEnabled) { _, newValue in
                                    if newValue {
                                        checkBiometricAvailability()
                                    } else {
                                        appLockEnabled = false
                                        ToastManager.shared.show(title: "Biometrics Disabled", message: "Face ID / Touch ID has been disabled for login.", type: .success)
                                    }
                                }
                            Divider().padding(.leading, 60).padding(.trailing, 20)
                            ToggleRow(title: "Require for App Launch", icon: "lock.shield", isOn: $appLockEnabled)
                                .onChange(of: appLockEnabled) { _, newValue in
                                    if newValue && !biometricsEnabled {
                                        appLockEnabled = false
                                        ToastManager.shared.show(title: "Enable Biometrics First", message: "You must enable 'Use Biometrics' before requiring it for app launch.", type: .error)
                                    } else if newValue {
                                        ToastManager.shared.show(title: "App Lock Enabled", message: "LawMate will require biometrics on every launch.", type: .success)
                                    }
                                }
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
            
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
    }

    private func checkBiometricAvailability() {
        let context = LocalAuthentication.LAContext()
        var error: NSError?
        
        if !context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricsEnabled = false
            ToastManager.shared.show(title: "Unavailable", message: "Face ID / Touch ID is not configured or available on this device.", type: .error)
        } else {
            ToastManager.shared.show(title: "Biometrics Enabled", message: "Face ID / Touch ID will be used for your next login.", type: .success)
        }
    }
}

struct ToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.lmPrimary)
                .frame(width: 24)
            
            Toggle(title, isOn: $isOn)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.lmTextPrimary)
                .tint(.lmPrimary)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
}

#Preview {
    BiometricsView()
}
