import SwiftUI

struct RatingView: View {
    let lawyerName: String
    @Environment(\.dismiss) private var dismiss
    @State private var rating: Int = 0
    @State private var reviewText: String = ""
    @State private var isSubmitted: Bool = false
    
    var body: some View {
        ZStack {
            Color.lmBackground.ignoresSafeArea()
            
            // Background Blobs
            VStack {
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color.lmPrimary.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .blur(radius: 50)
                }
                Spacer()
                HStack {
                    Circle()
                        .fill(Color.lmPrimary.opacity(0.1))
                        .frame(width: 300, height: 300)
                        .blur(radius: 70)
                    Spacer()
                }
            }
            .ignoresSafeArea()
            
            if isSubmitted {
                successView
            } else {
                ratingForm
            }
        }
    }
    
    private var ratingForm: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Text("Rate Your Experience")
                    .font(.lmTitle)
                    .foregroundColor(.lmPrimary)
                
                Text("How was your consultation with \(lawyerName)?")
                    .font(.lmHeading)
                    .foregroundColor(.lmTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 40)
            
            // Star Rating
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(index <= rating ? .orange : .gray.opacity(0.3))
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                rating = index
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                }
            }
            .padding(.vertical, 20)
            
            // Text Review
            VStack(alignment: .leading, spacing: 12) {
                Text("Share more details (Optional)")
                    .font(.lmCaption)
                    .foregroundColor(.lmTextSecondary.opacity(0.7))
                    .padding(.horizontal, 4)
                
                ZStack(alignment: .topLeading) {
                    if reviewText.isEmpty {
                        Text("Tell us what you liked or what could be improved...")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.4))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                    }
                    
                    TextEditor(text: $reviewText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.lmTextPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .frame(height: 150)
                .background(Color.white.opacity(0.6))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Submit Button
            LawMatePrimaryButton(title: "Submit Rating") {
                withAnimation {
                    isSubmitted = true
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            .disabled(rating == 0)
            .opacity(rating == 0 ? 0.6 : 1.0)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    private var successView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.lmPrimary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.lmPrimary)
            }
            
            VStack(spacing: 8) {
                Text("Thank You!")
                    .font(.lmTitle)
                    .foregroundColor(.lmPrimary)
                
                Text("Your feedback helps us improve the LawMate experience.")
                    .font(.lmHeading)
                    .foregroundColor(.lmTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.lmButton)
                    .foregroundColor(.lmPrimary)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(Color.lmPrimary.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.top, 20)
        }
    }
}

#Preview {
    RatingView(lawyerName: "Nimal Perera")
}
