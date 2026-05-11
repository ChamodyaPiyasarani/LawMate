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
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(1)
            }
            .frame(maxWidth: maxWidth)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isActive ? Color.lmPrimary : Color.white)
            .foregroundColor(isActive ? .white : .lmPrimary)
            .clipShape(Capsule())
            .shadow(color: isActive ? Color.lmPrimary.opacity(0.15) : Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
            .overlay(
                Capsule()
                    .stroke(isActive ? Color.clear : Color.lmPrimary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
