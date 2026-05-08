import SwiftUI

// MARK: - Filter Pill
struct LawMateFilterPill: View {
    let icon: String
    let title: String
    var isActive: Bool = false
    var maxWidth: CGFloat? = nil
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(1)
            }
            .frame(maxWidth: maxWidth)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isActive ? Color.lmPrimary : Color.lmPrimary.opacity(0.05))
            .foregroundColor(isActive ? Color.white : .lmPrimary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isActive ? Color.clear : Color.lmPrimary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
