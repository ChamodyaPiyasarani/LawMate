import SwiftUI

struct LawMatePrimaryButton: View {
    let title: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.lmButton)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.lmPrimary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Secondary / outline style button
struct LawMateSecondaryButton: View {
    let title: String
    var icon: String? = nil
    var titleColor: Color = .lmTextPrimary
    var iconColor: Color = .lmTextPrimary
    var font: Font = .lmButton
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(iconColor)
                }
                Text(title)
                    .font(font)
                    .foregroundColor(titleColor)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack(spacing: 16) {
        LawMatePrimaryButton(title: "Sign up")
        LawMateSecondaryButton(title: "Enable Biometric Authentication",
                               icon: "faceid")
    }
    .padding()
    .background(Color.lmBackground)
}
