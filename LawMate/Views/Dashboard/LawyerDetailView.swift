import SwiftUI
import MapKit

struct LawyerDetailView: View {
    let lawyer: Lawyer
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToBooking = false
    @State private var showRatingSheet = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Green blob top-left (Client Style)
            GreenBlobBackground(style: .client)
                .frame(height: 300)

            VStack(spacing: 0) {
                // MARK: Custom Header
                LawMateNavigationBar(
                    title: "Lawyer Details",
                    showBack: true,
                    showNotification: true,
                    showCamera: false,
                    onBack: { dismiss() }
                )
                .padding(.top, 48)


                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        
                        // MARK: Profile Section
                        VStack(spacing: 20) {
                            Text(lawyer.name)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.lmPrimary)

                            ZStack(alignment: .bottomTrailing) {
                                // Profile Image Placeholder
                                RoundedRectangle(cornerRadius: 32, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1.5, contentMode: .fill)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 80))
                                            .foregroundColor(.lmPrimary.opacity(0.2))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                
                                // Rating Badge
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.orange)
                                    Text(String(format: "%.1f", lawyer.rating))
                                        .fontWeight(.bold)
                                        .foregroundColor(.lmTextPrimary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.white)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                .offset(x: -20, y: 15)
                            }
                        }
                        .padding(.horizontal, 24)

                        // MARK: Stats Row
                        HStack(spacing: 16) {
                            StatCard(title: "EXPERIENCE", value: lawyer.experience)
                            StatCard(title: "CASES WON", value: lawyer.casesWon)
                        }
                        .padding(.horizontal, 24)

                        // MARK: Description
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Description:")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.lmPrimary)

                            Text(lawyer.description)
                                .font(.system(size: 16))
                                .foregroundColor(.lmTextSecondary)
                                .lineSpacing(6)
                        }
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 24) // Controlled gap

                        // MARK: Ratings & Reviews
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Ratings & Reviews")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.lmPrimary)
                                
                                Spacer()
                                
                                Button {
                                    showRatingSheet = true
                                } label: {
                                    Text("Write a review")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.lmPrimary)
                                }
                            }
                            
                            // Mock Review Example
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(Color.lmPrimary.opacity(0.1))
                                    .frame(width: 36, height: 36)
                                    .overlay(Text("JS").font(.system(size: 12, weight: .bold)).foregroundColor(.lmPrimary))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        ForEach(0..<5) { i in
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(i < 5 ? .orange : .gray.opacity(0.3))
                                        }
                                        Spacer()
                                        Text("2 days ago")
                                            .font(.system(size: 10))
                                            .foregroundColor(.lmTextSecondary.opacity(0.6))
                                    }
                                    
                                    Text("Very professional and clear in his explanations. Highly recommended for complex cases.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.lmTextSecondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)

                        // MARK: CTA
                        LawMatePrimaryButton(title: "Book An Appointment") {
                            navigateToBooking = true
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20) // Extra button spacing
                        
                        // Footer padding for global TabBar
                        Color.clear.frame(height: 220)
                    }
                    .padding(.top, 20)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToBooking) {
            BookingView(lawyer: lawyer)
        }
        .sheet(isPresented: $showRatingSheet) {
            RatingView(lawyerName: lawyer.name)
        }
    }
}

#Preview {
    LawyerDetailView(lawyer: Lawyer(
        id: "L1",
        name: "Nimal Perera",
        specialty: "Criminal Law",
        bio: "Experienced criminal lawyer",
        description: "Experienced criminal defense lawyer with over 14 years of practice. Known for strong courtroom representation and client-focused strategies.",
        experience: "14 YEARS",
        casesWon: "250 +",
        rating: 4.8,
        location: "Colombo, Sri Lanka",
        image: "person.fill",
        coordinate: .init(latitude: 6.9271, longitude: 79.8612)
    ))
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.lmTextSecondary.opacity(0.6))
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.lmPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}
