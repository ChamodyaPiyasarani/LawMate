import SwiftUI
import MapKit

struct LawyerDetailView: View {
    let lawyer: Lawyer
    var referringLawyerName: String? = nil
    @Environment(\.dismiss) private var dismiss
    @Binding var navPath: NavigationPath
    @Binding var activeConversation: FBConversation?
    @EnvironmentObject var firestore: FirestoreManager
    @EnvironmentObject var auth: AuthService
    @State private var showRatingSheet = false
    @State private var showReferralAlert = false
    @State private var referralNote = ""
    
    private func startChat() {
        guard let currentUser = auth.currentUser else { return }
        let partnerInfo = (name: lawyer.name, image: (lawyer.image.count > 15 ? lawyer.image : nil))
        firestore.getOrCreateConversation(between: currentUser.id, and: lawyer.id, partnerInfo: partnerInfo, currentUser: currentUser) { convId in
            if let conversation = firestore.conversations.first(where: { $0.id == convId }) {
                activeConversation = conversation
            } else {
                firestore.db.collection("conversations").document(convId).getDocument { snap, _ in
                    if let conversation = try? snap?.data(as: FBConversation.self) {
                        DispatchQueue.main.async {
                            activeConversation = conversation
                        }
                    }
                }
            }
        }
    }

    private var isLawyerAvailable: Bool {
        firestore.lawyers.contains(where: { $0.id == lawyer.id })
    }

    var body: some View {
        Group {
            if isLawyerAvailable {
                mainContent
            } else {
                Color.lmBackground
                    .onAppear {
                        ToastManager.shared.show(
                            title: "Lawyer Unavailable",
                            message: "This lawyer profile has been deleted or is no longer available.",
                            type: .error
                        )
                        dismiss()
                    }
            }
        }
    }

    private var mainContent: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Modern Header Background
            GreenBlobBackground(style: .client)
                .frame(height: 350)
                .offset(y: -50)

            VStack(spacing: 0) {
                // MARK: Custom Navigation
                LawMateNavigationBar(
                    title: "Lawyer Details",
                    showBack: true,
                    showNotification: true,
                    onBack: { dismiss() }
                )
                .padding(.top, 65)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // MARK: Hero Profile Section
                        VStack(spacing: 16) {
                            ZStack(alignment: .bottomTrailing) {
                                LawMateAvatar(url: lawyer.image, name: lawyer.name, size: 120)
                                    .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
                                
                                // Rating Badge
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.orange)
                                    Text(String(format: "%.1f", lawyer.rating))
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                .offset(x: 5, y: 5)
                            }
                            
                            VStack(spacing: 4) {
                                Text(lawyer.name)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.lmPrimary)
                                
                                Text(lawyer.specialty)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.lmTextSecondary)
                            }
                            
                            if let referringLawyerName {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrowshape.turn.up.right.fill")
                                        .font(.system(size: 10))
                                    Text("Referred by \(referringLawyerName)")
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.lmPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.lmPrimary.opacity(0.08))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.top, 20)

                        // MARK: Primary Actions Row (Modern & Compact)
                        HStack(spacing: 32) {
                            ActionButton(icon: "bubble.left.fill", title: "Message", color: .white, textColor: .lmPrimary, borderColor: .lmPrimary.opacity(0.1)) {
                                startChat()
                            }
                            
                            ActionButton(icon: "calendar", title: "Book", color: .lmPrimary, textColor: .white) {
                                navPath.append(ClientHomeView.AppRoute.booking(lawyer))
                            }
                            
                            ActionButton(icon: "person.2.fill", title: "Refer", color: .lmPrimary.opacity(0.05), textColor: .lmPrimary) {
                                showReferralAlert = true
                            }
                        }
                        .padding(.vertical, 10)

                        // MARK: Info Cards
                        HStack(spacing: 16) {
                            InfoCard(icon: "briefcase.fill", title: "Experience", value: lawyer.experience)
                            InfoCard(icon: "trophy.fill", title: "Cases Won", value: lawyer.casesWon)
                        }
                        .padding(.horizontal, 24)

                        // MARK: About Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About Lawyer")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.lmPrimary)

                            Text(lawyer.description)
                                .font(.system(size: 15))
                                .foregroundColor(.lmTextSecondary)
                                .lineSpacing(4)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 5)
                        )
                        .padding(.horizontal, 24)

                        // MARK: Reviews Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Reviews")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.lmPrimary)
                                
                                Spacer()
                                
                                Button {
                                    showRatingSheet = true
                                } label: {
                                    Text("Write a Review")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.lmPrimary)
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            if firestore.lawyerReviews.isEmpty {
                                Text("No reviews yet. Be the first to share your experience!")
                                    .font(.system(size: 13))
                                    .foregroundColor(.lmTextSecondary.opacity(0.6))
                                    .padding(.horizontal, 24)
                                    .padding(.top, 8)
                            } else {
                                ForEach(firestore.lawyerReviews) { review in
                                    ReviewItem(review: review)
                                        .padding(.horizontal, 24)
                                }
                            }
                        }
                        .padding(.bottom, 120)
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showRatingSheet) {
            RatingView(lawyerName: lawyer.name, lawyerId: lawyer.id)
        }
        .alert("Request a Referral", isPresented: $showReferralAlert) {
            TextField("Optional note", text: $referralNote)
            Button("Send") {
                firestore.createReferralRequest(
                    targetLawyerId: lawyer.id,
                    targetLawyerName: lawyer.name,
                    note: referralNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : referralNote
                )
                referralNote = ""
                ToastManager.shared.show(title: "Request Sent", message: "Your referral request was sent.", type: .success)
            }
            Button("Cancel", role: .cancel) {
                referralNote = ""
            }
        } message: {
            Text("Ask this lawyer to recommend another lawyer for your case.")
        }
        .onAppear {
            firestore.listenForReviews(forLawyerId: lawyer.id)
        }
    }
}

// MARK: - Subviews

private struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let textColor: Color
    var borderColor: Color? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 56, height: 56)
                        .shadow(color: color.opacity(0.15), radius: 10, x: 0, y: 6)
                    
                    if let borderColor = borderColor {
                        Circle()
                            .stroke(borderColor, lineWidth: 1.5)
                            .frame(width: 56, height: 56)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(textColor)
                }
                
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.lmTextSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.lmPrimary.opacity(0.05))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.lmPrimary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.lmTextSecondary.opacity(0.6))
                Text(value)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.lmPrimary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
}

private struct ReviewItem: View {
    let review: FBReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.lmPrimary.opacity(0.1))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(review.clientName.prefix(1))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.lmPrimary)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.clientName)
                        .font(.system(size: 13, weight: .bold))
                    HStack(spacing: 2) {
                        ForEach(0..<5) { i in
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundColor(i < review.rating ? .orange : .gray.opacity(0.3))
                        }
                    }
                }
                Spacer()
                Text(formatTimestamp(review.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(.lmTextSecondary.opacity(0.6))
            }
            
            Text(review.reviewText)
                .font(.system(size: 13))
                .foregroundColor(.lmTextSecondary)
                .lineLimit(3)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        LawyerDetailView(lawyer: Lawyer(
            id: "L1",
            name: "Nimal Perera",
            specialty: "Criminal Law",
            bio: "Experienced criminal lawyer",
            description: "Experienced criminal defense lawyer with over 14 years of practice. Known for strong courtroom representation and client-focused strategies.",
            experience: "14 YEARS",
            experienceYears: 14,
            casesWon: "250 +",
            wonCount: 250,
            rating: 4.8,
            reviewCount: 120,
            location: "Colombo, Sri Lanka",
            image: "person.fill",
            coordinate: .init(latitude: 6.9271, longitude: 79.8612)
        ), navPath: .constant(NavigationPath()), activeConversation: .constant(nil))
    }
}
