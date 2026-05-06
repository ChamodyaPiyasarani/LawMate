import SwiftUI
import MapKit

struct ReferralNetworkView: View {
    @Binding var navPath: NavigationPath
    @EnvironmentObject var firestore: FirestoreManager
    @EnvironmentObject var auth: AuthService

    private var myReferrals: [FBReferral] {
        firestore.referrals.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            GreenBlobBackground(style: .client)
                .frame(height: 300)

            VStack(spacing: 0) {
                LawMateNavigationBar(title: "Referral Network", showBack: true, onBack: { navPath.removeLast() })
                    .padding(.top, 64)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if myReferrals.isEmpty {
                            emptyState
                        } else {
                            ForEach(myReferrals) { referral in
                                referralCard(referral)
                            }
                        }
                        Color.clear.frame(height: 120)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if let user = auth.currentUser {
                firestore.listenForReferrals(userId: user.id, role: user.role)
            }
        }
    }

    private func referralCard(_ referral: FBReferral) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(referral.targetLawyerName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.lmPrimary)
                Spacer()
                Text(referral.status)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(statusColor(referral.status))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor(referral.status).opacity(0.1))
                    .clipShape(Capsule())
            }

            if let note = referral.note, !note.isEmpty {
                Text(note)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.lmTextSecondary)
            }

            if let recommendedName = referral.recommendedLawyerName, !recommendedName.isEmpty {
                Text("Recommended: \(recommendedName)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.lmPrimary)

                if let recommended = recommendedLawyer(for: referral) {
                    NavigationLink(value: recommended) {
                        Text("View Lawyer")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.lmPrimary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.7))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.3), lineWidth: 1))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrowshape.turn.up.right.fill")
                .font(.system(size: 42))
                .foregroundColor(.lmPrimary.opacity(0.2))
            Text("No referral requests yet")
                .font(.lmHeading)
                .foregroundColor(.lmPrimary.opacity(0.6))
            Text("Request a referral from a lawyer to get started.")
                .font(.lmCaption)
                .foregroundColor(.lmTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 64)
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "recommended": return .green
        case "declined": return .red
        default: return .orange
        }
    }

    private func recommendedLawyer(for referral: FBReferral) -> Lawyer? {
        guard let id = referral.recommendedLawyerId else { return nil }
        guard let user = firestore.lawyers.first(where: { $0.id == id }) else { return nil }
        return mapToLawyer(user)
    }

    private func mapToLawyer(_ user: User) -> Lawyer {
        let expValue = Int(user.experience?.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }.first ?? "0") ?? 0
        let wonValue = Int(user.casesWon?.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }.first ?? "0") ?? 0
        let lat = user.latitude ?? 6.9271
        let lng = user.longitude ?? 79.8612
        return Lawyer(
            id: user.id,
            name: user.fullName,
            specialty: user.specialty ?? "General Practice",
            bio: user.bio ?? "Professional Lawyer",
            description: user.bio ?? "",
            experience: user.experience ?? "",
            experienceYears: expValue,
            casesWon: user.casesWon ?? "0",
            wonCount: wonValue,
            rating: user.rating ?? 0.0,
            reviewCount: user.reviewCount ?? 0,
            location: user.address ?? "",
            image: user.profileImage ?? "",
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
        )
    }
}

struct ReferralRequestsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firestore: FirestoreManager
    @EnvironmentObject var auth: AuthService
    @State private var selectedReferral: FBReferral? = nil
    @State private var showRecommendSheet = false

    private var pendingRequests: [FBReferral] {
        firestore.referrals.filter { $0.status.lowercased() == "pending" }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            GreenBlobBackground(style: .lawyer)
                .frame(height: 300)

            VStack(spacing: 0) {
                LawMateNavigationBar(title: "Referral Requests", showBack: true, onBack: { dismiss() })
                    .padding(.top, 64)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if pendingRequests.isEmpty {
                            emptyState
                        } else {
                            ForEach(pendingRequests) { referral in
                                requestCard(referral)
                            }
                        }
                        Color.clear.frame(height: 120)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showRecommendSheet) {
            RecommendLawyerSheet(
                referral: $selectedReferral,
                onSelect: { lawyer in
                    guard let referralId = selectedReferral?.id else { return }
                    firestore.recommendReferral(
                        referralId: referralId,
                        recommendedLawyerId: lawyer.id,
                        recommendedLawyerName: lawyer.name
                    ) { _ in }
                    selectedReferral = nil
                    showRecommendSheet = false
                }
            )
        }
        .onAppear {
            if let user = auth.currentUser {
                firestore.listenForReferrals(userId: user.id, role: user.role)
            }
        }
    }

    private func requestCard(_ referral: FBReferral) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(referral.requesterName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.lmPrimary)
                Spacer()
                Text(timeAgo(referral.timestamp))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.lmTextSecondary)
            }

            if let note = referral.note, !note.isEmpty {
                Text(note)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.lmTextSecondary)
            }

            HStack(spacing: 12) {
                Button {
                    selectedReferral = referral
                    showRecommendSheet = true
                } label: {
                    Text("Recommend")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.lmPrimary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    guard let referralId = referral.id else { return }
                    firestore.declineReferral(referralId: referralId) { _ in }
                } label: {
                    Text("Decline")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.red)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.7))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.3), lineWidth: 1))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrowshape.turn.up.right.fill")
                .font(.system(size: 42))
                .foregroundColor(.lmPrimary.opacity(0.2))
            Text("No referral requests")
                .font(.lmHeading)
                .foregroundColor(.lmPrimary.opacity(0.6))
            Text("Requests from clients will show up here.")
                .font(.lmCaption)
                .foregroundColor(.lmTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 64)
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

private struct RecommendLawyerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firestore: FirestoreManager
    @Binding var referral: FBReferral?
    var onSelect: (Lawyer) -> Void

    private var candidates: [Lawyer] {
        let currentId = AuthService.shared.currentUser?.id
        return firestore.lawyers
            .filter { $0.id != currentId }
            .map { user in
                let expValue = Int(user.experience?.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }.first ?? "0") ?? 0
                let wonValue = Int(user.casesWon?.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }.first ?? "0") ?? 0
                let lat = user.latitude ?? 6.9271
                let lng = user.longitude ?? 79.8612
                return Lawyer(
                    id: user.id,
                    name: user.fullName,
                    specialty: user.specialty ?? "General Practice",
                    bio: user.bio ?? "Professional Lawyer",
                    description: user.bio ?? "",
                    experience: user.experience ?? "",
                    experienceYears: expValue,
                    casesWon: user.casesWon ?? "0",
                    wonCount: wonValue,
                    rating: user.rating ?? 0.0,
                    reviewCount: user.reviewCount ?? 0,
                    location: user.address ?? "",
                    image: user.profileImage ?? "",
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
                )
            }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Recommend a Lawyer")
                .font(.lmHeading)
                .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(candidates) { lawyer in
                        Button {
                            onSelect(lawyer)
                        } label: {
                            HStack {
                                LawMateAvatar(url: lawyer.image, name: lawyer.name, size: 44)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(lawyer.name)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.lmPrimary)
                                    Text(lawyer.specialty)
                                        .font(.system(size: 12))
                                        .foregroundColor(.lmTextSecondary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lmPrimary.opacity(0.1), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button("Close") {
                dismiss()
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.lmPrimary)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
        .onAppear {
            firestore.listenForLawyers()
        }
    }
}
