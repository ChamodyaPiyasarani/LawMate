import SwiftUI
import MapKit

struct ReferralLawyerContext: Hashable {
    let lawyer: Lawyer
    let referringLawyerName: String
}

struct ReferralNetworkView: View {
    @Binding var navPath: NavigationPath
    @Binding var activeConversation: FBConversation?
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
                    .padding(.top, 54)

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
                    if referral.status.lowercased() == "accepted" {
                        NavigationLink {
                            ReferralConfirmationView(
                                referral: referral,
                                recommended: recommended,
                                referringLawyerName: referral.targetLawyerName,
                                navPath: $navPath,
                                activeConversation: $activeConversation
                            )
                        } label: {
                            Text("Open Referral")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(Color.lmPrimary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("Waiting for acceptance")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.lmTextSecondary)
                    }
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
    @State private var showIntroSheet = false
    @State private var introMessage = ""
    @Binding var activeConversation: FBConversation?
    @State private var selectedTab: ReferralInboxTab = .requests

    enum ReferralInboxTab: String, CaseIterable, Identifiable {
        case requests = "Requests"
        case incoming = "Incoming"

        var id: String { rawValue }
    }

    private var pendingRequests: [FBReferral] {
        guard let currentId = auth.currentUser?.id else { return [] }
        return firestore.referrals.filter {
            $0.targetLawyerId == currentId && $0.status.lowercased() == "pending"
        }
    }

    private var trackingRequests: [FBReferral] {
        guard let currentId = auth.currentUser?.id else { return [] }
        return firestore.referrals.filter {
            $0.targetLawyerId == currentId && $0.status.lowercased() != "pending"
        }
    }

    private var incomingReferrals: [FBReferral] {
        guard let currentId = auth.currentUser?.id else { return [] }
        return firestore.referrals.filter {
            $0.recommendedLawyerId == currentId
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            GreenBlobBackground(style: .lawyer)
                .frame(height: 300)

            VStack(spacing: 0) {
                LawMateNavigationBar(title: "Referral Requests", showBack: true, onBack: { dismiss() })
                    .padding(.top, 54)

                Picker("Referral Inbox", selection: $selectedTab) {
                    ForEach(ReferralInboxTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if selectedTab == .requests {
                            if pendingRequests.isEmpty && trackingRequests.isEmpty {
                                emptyState
                            } else {
                                ForEach(pendingRequests) { referral in
                                    requestCard(referral)
                                }
                                ForEach(trackingRequests) { referral in
                                    trackingCard(referral)
                                }
                            }
                        } else {
                            if incomingReferrals.isEmpty {
                                incomingEmptyState
                            } else {
                                ForEach(incomingReferrals) { referral in
                                    incomingCard(referral)
                                }
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
        .sheet(isPresented: $showIntroSheet) {
            ReferralIntroductionSheet(
                message: $introMessage,
                onSend: {
                    guard let referralId = selectedReferral?.id else { return }
                    let trimmed = introMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    firestore.sendReferralIntroduction(referralId: referralId, message: trimmed) { _ in }
                    introMessage = ""
                    selectedReferral = nil
                    showIntroSheet = false
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

    private func trackingCard(_ referral: FBReferral) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(referral.requesterName)
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

            if let recommendedName = referral.recommendedLawyerName {
                Text("Recommended: \(recommendedName)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.lmTextSecondary)
            }

            Button {
                selectedReferral = referral
                showIntroSheet = true
            } label: {
                Text("Introduce Client")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.lmPrimary)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.lmPrimary.opacity(0.08))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.white.opacity(0.7))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.3), lineWidth: 1))
    }

    private func incomingCard(_ referral: FBReferral) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(referral.requesterName)
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

            Text("Referred by \(referral.targetLawyerName)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.lmTextSecondary)

            if let note = referral.note, !note.isEmpty {
                Text(note)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.lmTextSecondary)
            }

            if referral.status.lowercased() == "recommended" {
                HStack(spacing: 12) {
                    Button {
                        guard let referralId = referral.id else { return }
                        firestore.acceptReferral(referralId: referralId) { _ in }
                    } label: {
                        Text("Accept")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        guard let referralId = referral.id else { return }
                        firestore.rejectReferral(referralId: referralId) { _ in }
                    } label: {
                        Text("Reject")
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

            if referral.status.lowercased() == "accepted" {
                Button {
                    startChat(with: referral.requesterId, name: referral.requesterName)
                } label: {
                    Text("Contact Client")
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

    private var incomingEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrowshape.turn.up.right.fill")
                .font(.system(size: 42))
                .foregroundColor(.lmPrimary.opacity(0.2))
            Text("No incoming referrals")
                .font(.lmHeading)
                .foregroundColor(.lmPrimary.opacity(0.6))
            Text("Recommendations from other lawyers will show up here.")
                .font(.lmCaption)
                .foregroundColor(.lmTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 64)
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "accepted": return .green
        case "recommended": return .blue
        case "rejected", "declined": return .red
        default: return .orange
        }
    }

    private func startChat(with userId: String, name: String) {
        guard let currentUser = auth.currentUser else { return }
        let partnerInfo: (name: String, image: String?) = (name: name, image: nil)
        firestore.getOrCreateConversation(between: currentUser.id, and: userId, partnerInfo: partnerInfo, currentUser: currentUser) { convId in
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

private struct ReferralIntroductionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var message: String
    var onSend: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Introduce Client")
                .font(.lmHeading)
                .padding(.top, 12)

            TextField("Write a short introduction...", text: $message, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(4...6)

            Button("Send Introduction") {
                onSend()
                dismiss()
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.lmPrimary)
            .clipShape(Capsule())

            Button("Cancel") {
                dismiss()
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.lmPrimary)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
    }
}

struct ReferralConfirmationView: View {
    let referral: FBReferral
    let recommended: Lawyer
    let referringLawyerName: String
    @Binding var navPath: NavigationPath
    @Binding var activeConversation: FBConversation?
    @EnvironmentObject var firestore: FirestoreManager
    @EnvironmentObject var auth: AuthService

    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            GreenBlobBackground(style: .client)
                .frame(height: 300)

            VStack(spacing: 0) {
                LawMateNavigationBar(title: "Referral Confirmed", showBack: true, onBack: { navPath.removeLast() })
                    .padding(.top, 54)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        Text("Referred by \(referringLawyerName)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.lmTextSecondary)

                        VStack(spacing: 12) {
                            LawMateAvatar(url: recommended.image, name: recommended.name, size: 64)
                            Text(recommended.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.lmPrimary)
                            Text(recommended.specialty)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.lmTextSecondary)
                        }
                        .padding(.vertical, 12)

                        Button {
                            navPath.append(ReferralLawyerContext(lawyer: recommended, referringLawyerName: referringLawyerName))
                        } label: {
                            Text("View Lawyer Profile")
                                .font(.lmButton)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.lmPrimary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            startChat()
                        } label: {
                            Text("Start Chat")
                                .font(.lmButton)
                                .foregroundColor(.lmPrimary)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.lmPrimary, lineWidth: 2))
                        }
                        .buttonStyle(.plain)

                        Button {
                            navPath.append(ClientHomeView.AppRoute.booking(recommended))
                        } label: {
                            Text("Book Consultation")
                                .font(.lmButton)
                                .foregroundColor(.lmPrimary)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.lmPrimary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
    }

    private func startChat() {
        guard let currentUser = auth.currentUser else { return }
        let partnerInfo = (name: recommended.name, image: (recommended.image.count > 15 ? recommended.image : nil))
        firestore.getOrCreateConversation(between: currentUser.id, and: recommended.id, partnerInfo: partnerInfo, currentUser: currentUser) { convId in
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
}
