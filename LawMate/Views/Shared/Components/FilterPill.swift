import SwiftUI

// MARK: - Filter Pill
struct FilterPill: View {
    let icon: String
    let title: String
    var isActive: Bool = false
    var maxWidth: CGFloat? = nil
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .lineLimit(1)
            }
            .frame(maxWidth: maxWidth)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isActive ? Color.lmPrimary : Color.white)
            .foregroundColor(isActive ? Color.white : .lmPrimary)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
