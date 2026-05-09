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
    @State private var selectedReferral: FBReferral? = nil
    @State private var showEditSheet = false
    @State private var editNoteText = ""

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
                    .padding(.top, 65)

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
            
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if let user = auth.currentUser {
                firestore.listenForReferrals(userId: user.id, role: user.role)
            }
        }
        .sheet(isPresented: $showEditSheet) {
            editReferralSheet
        }
    }

    @ViewBuilder
    private var editReferralSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit Referral Request")
                    .font(.lmHeading)
                    .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note to Lawyer")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.lmTextSecondary)
                    
                    TextEditor(text: $editNoteText)
                        .padding(12)
                        .background(Color.black.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(height: 150)
                }
                .padding(.horizontal, 24)
                
                Button {
                    if var updated = selectedReferral {
                        updated.note = editNoteText
                        firestore.updateReferral(updated)
                    }
                    showEditSheet = false
                } label: {
                    Text("Save Changes")
                        .font(.lmHeading)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.lmPrimary)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                
                Spacer()
            }
            .navigationBarItems(trailing: Button("Cancel") { showEditSheet = false })
        }
    }

    private func referralCard(_ referral: FBReferral) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(referral.targetLawyerName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.lmPrimary)
                Spacer()
                
                Menu {
                    Button(role: .destructive) {
                        firestore.deleteReferral(referral)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    if referral.status.lowercased() == "pending" {
                        Button {
                            selectedReferral = referral
                            editNoteText = referral.note ?? ""
                            showEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.lmTextSecondary.opacity(0.5))
                }
                
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
        case "recommended", "accepted": return .green
        case "declined", "rejected": return .red
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
    @State private var showEditNoteSheet = false
    @State private var editNoteText = ""

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
                    .padding(.top, 65)

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
            
        }
        .ignoresSafeArea(edges: .top)
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
                onSend: { mentionedClientId in
                    guard let referralId = selectedReferral?.id else { return }
                    let trimmed = introMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    
                    // Send introduction to Firestore
                    firestore.sendReferralIntroduction(referralId: referralId, message: trimmed) { _ in
                        // If a client was mentioned, send them a notification
                        if let clientId = mentionedClientId {
                            let lawyerId = auth.currentUser?.id ?? ""
                            let lawyerName = auth.currentUser?.fullName ?? "A Lawyer"
                            
                            let notification = FBNotification(
                                title: "New Lawyer Introduction",
                                body: "\(lawyerName) has mentioned you in an introduction note.",
                                type: "lawyer_profile",
                                timestamp: Date(),
                                relatedId: lawyerId
                            )
                            
                            firestore.addNotification(notification, toUserId: clientId)
                        }
                    }
                    
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
                
                Menu {
                    Button(role: .destructive) {
                        firestore.deleteReferral(referral)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .padding(4)
                        .foregroundColor(.lmTextSecondary)
                }
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
                
                Menu {
                    Button(role: .destructive) {
                        firestore.deleteReferral(referral)
                    } label: {
                        Label("Delete Record", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .padding(4)
                        .foregroundColor(.lmTextSecondary)
                }
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
            .disabled(referral.status.lowercased() == "declined")
            .opacity(referral.status.lowercased() == "declined" ? 0.5 : 1.0)
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
        case "accepted", "recommended": return .green
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
    @EnvironmentObject var firestore: FirestoreManager
    @EnvironmentObject var auth: AuthService
    @Binding var message: String
    var onSend: (String?) -> Void // Returns mentionedClientId if any

    @State private var showMentions = false
    @State private var mentionSearchQuery = ""
    @State private var selectedClientId: String? = nil

    var filteredClients: [User] {
        if mentionSearchQuery.isEmpty {
            return firestore.clients
        } else {
            return firestore.clients.filter { $0.fullName.lowercased().contains(mentionSearchQuery.lowercased()) }
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            GreenBlobBackground(style: .lawyer)
                .frame(height: 220)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Introduce Client")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.lmPrimary)
                        Text("Share thoughts or mention a specific client")
                            .font(.lmCaption)
                            .foregroundColor(.lmTextSecondary)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.lmPrimary.opacity(0.2))
                    }
                }
                .padding(.top, 40)

                // Note Input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Introduction Note")
                        .font(.lmCaption.weight(.bold))
                        .foregroundColor(.lmPrimary)
                        .padding(.leading, 4)
                    
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 10)
                        
                        TextEditor(text: $message)
                            .font(.lmBody)
                            .padding(16)
                            .scrollContentBackground(.hidden)
                            .frame(height: 200)
                            .onChange(of: message) { _, newValue in
                                handleMention(newValue)
                            }

                        if message.isEmpty {
                            Text("Write a short introduction... use @ to tag a client")
                                .font(.lmBody)
                                .foregroundColor(.lmTextSecondary.opacity(0.4))
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                                .allowsHitTesting(false)
                        }
                    }
                    .overlay(alignment: .top) {
                        if showMentions && !filteredClients.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("TAG CLIENT")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.lmTextSecondary)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)
                                    .padding(.bottom, 6)
                                
                                ScrollView {
                                    LazyVStack(spacing: 0) {
                                        ForEach(filteredClients) { client in
                                            Button {
                                                insertMention(client: client)
                                            } label: {
                                                HStack(spacing: 12) {
                                                    LawMateAvatar(url: client.profileImage, name: client.fullName, size: 36)
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(client.fullName)
                                                            .font(.system(size: 14, weight: .semibold))
                                                            .foregroundColor(.lmPrimary)
                                                        Text(client.email)
                                                            .font(.system(size: 10))
                                                            .foregroundColor(.lmTextSecondary)
                                                    }
                                                    Spacer()
                                                    Image(systemName: "at")
                                                        .font(.caption)
                                                        .foregroundColor(.lmPrimary.opacity(0.3))
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .contentShape(Rectangle())
                                            }
                                            Divider().padding(.horizontal, 16).opacity(0.5)
                                        }
                                    }
                                }
                                .frame(maxHeight: 180)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                            )
                            .padding(.top, 210) // Positioned just below the TextEditor
                            .transition(.asymmetric(insertion: .scale(scale: 0.9, anchor: .top).combined(with: .opacity), removal: .opacity))
                        }
                    }
                }

                Spacer()

                // Actions
                VStack(spacing: 16) {
                    Button {
                        onSend(selectedClientId)
                        dismiss()
                    } label: {
                        HStack {
                            Text("Send Introduction")
                            Image(systemName: "paperplane.fill")
                        }
                        .font(.lmButton)
                        .foregroundColor(.white)
                        .padding(.vertical, 18)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : Color.lmPrimary)
                        )
                        .shadow(color: Color.lmPrimary.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button { dismiss() } label: {
                        Text("Cancel")
                            .font(.lmButton)
                            .foregroundColor(.lmPrimary)
                            .padding(.vertical, 12)
                    }
                }
                .padding(.bottom, 34)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            firestore.listenForClients()
        }
    }

    private func handleMention(_ newValue: String) {
        if let lastAt = newValue.lastIndex(of: "@") {
            let afterAt = newValue[newValue.index(after: lastAt)...]
            if !afterAt.contains(" ") {
                mentionSearchQuery = String(afterAt)
                showMentions = true
                return
            }
        }
        showMentions = false
    }

    private func insertMention(client: User) {
        if let lastAt = message.lastIndex(of: "@") {
            let prefix = message[..<lastAt]
            message = String(prefix) + "@" + client.fullName + " "
            selectedClientId = client.id
            showMentions = false
        }
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
            
            // Success background blobs
            Circle()
                .fill(Color.green.opacity(0.1))
                .frame(width: 400, height: 400)
                .offset(x: -100, y: -150)
                .blur(radius: 50)
            
            VStack(spacing: 0) {
                LawMateNavigationBar(title: "Referral Confirmed", showBack: true, onBack: { navPath.removeLast() })
                    .padding(.top, 65)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Success Icon & Message
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.green)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Great News!")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.lmPrimary)
                                
                                Text("Referred by \(referringLawyerName)")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.lmTextSecondary)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Lawyer Card
                        VStack(spacing: 20) {
                            HStack(spacing: 16) {
                                LawMateAvatar(url: recommended.image, name: recommended.name, size: 80)
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(recommended.name)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.lmPrimary)
                                    
                                    HStack(spacing: 6) {
                                        Image(systemName: recommended.specialtyIcon)
                                            .font(.system(size: 10))
                                        Text(recommended.specialty)
                                            .font(.system(size: 13, weight: .bold))
                                    }
                                    .foregroundColor(.lmPrimary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.lmPrimary.opacity(0.1))
                                    .clipShape(Capsule())
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.orange)
                                        Text(String(format: "%.1f", recommended.rating))
                                            .fontWeight(.bold)
                                        Text("(\(recommended.reviewCount) reviews)")
                                            .foregroundColor(.lmTextSecondary)
                                    }
                                    .font(.system(size: 12))
                                    .padding(.top, 4)
                                }
                            }
                            
                            Divider()
                                .background(Color.lmPrimary.opacity(0.1))
                            
                            Text("You can now connect with \(recommended.name) regarding your legal matter. Choose an action below to get started.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.lmTextSecondary)
                                .lineSpacing(4)
                        }
                        .padding(24)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 8)
                        
                        // Actions
                        VStack(spacing: 16) {
                            if let caseId = referral.caseId {
                                Button {
                                    firestore.executeCaseHandover(caseId: caseId, approved: true, isCurrentLawyer: true) { _ in
                                        navPath.removeLast()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                                        Text("Confirm Case Transfer")
                                    }
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 16)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.orange)
                                    .clipShape(Capsule())
                                    .shadow(color: Color.orange.opacity(0.3), radius: 10, x: 0, y: 5)
                                }
                                .buttonStyle(.plain)
                            }

                            Button {
                                startChat()
                            } label: {
                                HStack {
                                    Image(systemName: "message.fill")
                                    Text("Start Chat")
                                }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(Color.lmPrimary)
                                .clipShape(Capsule())
                                .shadow(color: Color.lmPrimary.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .buttonStyle(.plain)
                            
                            HStack(spacing: 12) {
                                Button {
                                    navPath.append(ReferralLawyerContext(lawyer: recommended, referringLawyerName: referringLawyerName))
                                } label: {
                                    Text("View Profile")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.lmPrimary)
                                        .padding(.vertical, 14)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(Color.lmPrimary.opacity(0.2), lineWidth: 1.5))
                                }
                                .buttonStyle(.plain)
                                
                                Button {
                                    navPath.append(ClientHomeView.AppRoute.booking(recommended))
                                } label: {
                                    Text("Book Now")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.lmPrimary)
                                        .padding(.vertical, 14)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.lmPrimary.opacity(0.08))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Color.clear.frame(height: 50)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
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
