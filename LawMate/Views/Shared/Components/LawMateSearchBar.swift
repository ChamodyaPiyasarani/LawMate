import SwiftUI

struct LawMateSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    var onSubmit: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.lmPrimary.opacity(0.4))
            
            TextField(placeholder, text: $text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.lmTextPrimary)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit {
                    onSubmit?()
                }
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.lmTextSecondary.opacity(0.3))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.8))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    ZStack {
        Color.lmBackground.ignoresSafeArea()
        LawMateSearchBar(text: .constant(""), placeholder: "Search legal documents")
            .padding()
    }
}
