import SwiftUI

struct AccessibilitySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    @ObservedObject private var accManager = AccessibilityManager.shared
    
    @State private var textScale: Double = 1.0
    @State private var highContrast: Bool = false
    @State private var isSaving = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Background blob
            GreenBlobBackground(style: .client)
                .frame(height: 300)
            
            VStack(spacing: 0) {
                LawMateNavigationBar(title: "Accessibility", showBack: true, onBack: { dismiss() })
                    .padding(.top, 64)
                    .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // MARK: - Description Header
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Personalize your experience")
                                .font(.lmTitle)
                                .foregroundColor(.lmPrimary)
                            
                            Text("Adjust settings to make LawMate easier to see and interact with.")
                                .font(.lmBody)
                                .foregroundColor(.lmTextSecondary)
                        }
                        .padding(.top, 24)
                        
                        // MARK: - Text Scaling
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "textformat.size")
                                    .foregroundColor(.lmPrimary)
                                    .font(.system(size: 20))
                                Text("Text Scaling")
                                    .font(.lmHeading)
                                Spacer()
                                Text("\(Int(textScale * 100))%")
                                    .font(.lmBody.weight(.bold))
                                    .foregroundColor(.lmPrimary)
                            }
                            
                            Slider(value: $textScale, in: 1.0...2.0, step: 0.1) {
                                Text("Text Scale")
                            } minimumValueLabel: {
                                Text("A").font(.system(size: 12))
                            } maximumValueLabel: {
                                Text("A").font(.system(size: 24))
                            }
                            .accentColor(.lmPrimary)
                            
                            Text("Increase the size of text throughout the application.")
                                .font(.lmCaption)
                                .foregroundColor(.lmTextSecondary)
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.8))
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.5), lineWidth: 1))
                        
                        // MARK: - High Contrast
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle(isOn: $highContrast) {
                                HStack(spacing: 12) {
                                    Image(systemName: "circle.lefthalf.filled")
                                        .foregroundColor(.lmPrimary)
                                        .font(.system(size: 20))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("High Contrast")
                                            .font(.lmHeading)
                                        Text("Enhance legibility with stronger colors.")
                                            .font(.lmCaption)
                                            .foregroundColor(.lmTextSecondary)
                                    }
                                }
                            }
                            .tint(.lmPrimary)
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.8))
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.5), lineWidth: 1))
                        
                        // MARK: - Preview Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Preview")
                                .font(.lmHeading)
                                .foregroundColor(.lmPrimary)
                            
                            VStack(spacing: 16) {
                                // Content in preview that reacts to current @State
                                Text("Legal Advisory for You")
                                    .font(.lmHeading)
                                    .foregroundColor(.lmPrimary)
                                    .dynamicTypeSize(dynamicTypeSizeFor(textScale))
                                
                                Text("This is a sample text showing how your accessibility choices will appear across LawMate screens.")
                                    .font(.lmBody)
                                    .foregroundColor(.lmTextSecondary)
                                    .multilineTextAlignment(.center)
                                    .dynamicTypeSize(dynamicTypeSizeFor(textScale))
                                
                                LawMatePrimaryButton(title: "Sample Button") { }
                                    .frame(height: 50)
                            }
                            .padding(24)
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                            .environment(\.colorScheme, .light) // Static for preview
                        }
                        
                        // MARK: - Save Button
                        Button {
                            saveSettings()
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Apply & Save Preferences")
                                        .font(.lmButton)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.lmPrimary)
                            .clipShape(Capsule())
                        }
                        .disabled(isSaving)
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if let user = authService.currentUser {
                textScale = user.textScale ?? 1.0
                highContrast = user.highContrast ?? false
            }
        }
    }
    
    private func saveSettings() {
        isSaving = true
        
        // Use updateUserProfile with the new accessibility parameters
        authService.updateUserProfile(
            fullName: authService.currentUser?.fullName ?? "",
            phoneNumber: authService.currentUser?.phoneNumber ?? "",
            specialty: authService.currentUser?.specialty,
            experience: authService.currentUser?.experience,
            bio: authService.currentUser?.bio,
            textScale: textScale,
            highContrast: highContrast
        ) { _ in
            isSaving = false
        }
        
        // Show Success Toast
        ToastManager.shared.show(title: "Settings Saved", message: "Your accessibility preferences have been updated.", type: .success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSaving = false
            dismiss()
        }
    }
    
    private func dynamicTypeSizeFor(_ scale: Double) -> DynamicTypeSize {
        if scale <= 1.0 { return .large }
        if scale <= 1.15 { return .xLarge }
        if scale <= 1.3 { return .xxLarge }
        if scale <= 1.5 { return .xxxLarge }
        if scale <= 1.7 { return .accessibility1 }
        return .accessibility3
    }
}

#Preview {
    AccessibilitySettingsView()
}
