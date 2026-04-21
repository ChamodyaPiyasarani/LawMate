import SwiftUI


struct MessagesListView: View {
    var onBack: () -> Void = {}
    var onSelect: (FBConversation) -> Void = { _ in }
    
    @State private var showingNewChatSheet = false
    @StateObject private var firestore = FirestoreManager.shared
    @StateObject private var auth = AuthService.shared
    
    private var sortedConversations: [FBConversation] {
        firestore.conversations
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // blob style based on role
            GreenBlobBackground(style: auth.currentUser?.role == .lawyer ? .lawyer : .client)
                .frame(height: 300)
            
            VStack(spacing: 0) {
                // MARK: Left-Aligned Header
                HStack(alignment: .center) {
                    Text("Chat")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    Spacer()
                    
                    LawMatePlusButton(action: {
                        showingNewChatSheet = true
                    })
                }
                .padding(.horizontal, 24)
                .padding(.top, 64)
                .padding(.bottom, 24)
                .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if sortedConversations.isEmpty {
                            VStack(spacing: 12) {
                                Spacer().frame(height: 60)
                                Image(systemName: "message.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.lmPrimary.opacity(0.1))
                                Text("No Conversations Yet")
                                    .font(.lmHeading)
                                    .foregroundColor(.lmPrimary.opacity(0.5))
                                Text("Tap the + button to start a new chat.")
                                    .font(.lmCaption)
                                    .foregroundColor(.lmTextSecondary)
                            }
                        } else {
                            ForEach(sortedConversations) { conversation in
                                NavigationLink(value: conversation) {
                                    ChatPreviewCard(conversation: conversation)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 120) // Give space for bottom nav
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if let userId = auth.currentUser?.id {
                firestore.listenForConversations(userId: userId)
            }
        }
        .sheet(isPresented: $showingNewChatSheet) {
            NewChatSelectionView { contact in
                guard let currentUser = auth.currentUser else { return }
                
                // Start or fetch conversation
                firestore.getOrCreateConversation(
                    between: currentUser.id,
                    and: contact.id,
                    partnerInfo: (name: contact.name, image: contact.image),
                    currentUser: currentUser
                ) { conversationId in
                    // We need the full conversation object for navigation value matching.
                    // We'll look it up from the list or create a temporary one if not yet synced.
                    if let existing = firestore.conversations.first(where: { $0.id == conversationId }) {
                        onSelect(existing)
                    } else {
                        // Temp object to trigger navigation
                        var memberNames = [currentUser.id: currentUser.fullName, contact.id: contact.name]
                        var memberImages = [currentUser.id: currentUser.profileImage, contact.id: contact.image]
                        
                        let tempConv = FBConversation(
                            id: conversationId,
                            participants: [currentUser.id, contact.id].sorted(),
                            lastMessageAt: Date(),
                            memberNames: memberNames,
                            memberImages: memberImages
                        )
                        onSelect(tempConv)
                    }
                }
            }
        }
    }
}

// MARK: - Chat Preview Card
struct ChatPreviewCard: View {
    let conversation: FBConversation
    @StateObject private var auth = AuthService.shared
    
    var body: some View {
        let partner = conversation.partnerInfo(for: auth.currentUser?.id ?? "")
        
        HStack(spacing: 16) {
            // Avatar Placeholder
            ZStack(alignment: .bottomTrailing) {
                LawMateAvatar(url: partner.image, name: partner.name, size: 50)
                
                // We'll default to online for now as we don't have presence yet
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .offset(x: -2, y: -2)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(partner.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    if let userId = auth.currentUser?.id, let unread = conversation.unreadCounts?[userId], unread > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                    }
                    
                    Spacer()
                    
                    if let date = conversation.lastMessageAt {
                        Text(formatDate(date))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.lmPrimary)
                    }
                }
                
                HStack {
                    Text(conversation.lastMessage ?? "Start a conversation")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.lmTextSecondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let userId = auth.currentUser?.id, let unread = conversation.unreadCounts?[userId], unread > 0 {
                        Capsule()
                            .fill(Color.red)
                            .frame(height: 18)
                            .overlay(
                                Text("\(unread)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                            )
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.6))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else {
            formatter.dateFormat = "MMM d"
        }
        return formatter.string(from: date)
    }
}

#Preview {
    MessagesListView()
}

// MARK: - New Chat Selection
struct ChatContact: Identifiable {
    let id: String
    let name: String
    let image: String?
}

struct NewChatSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firestore = FirestoreManager.shared
    @StateObject private var auth = AuthService.shared
    
    var onSelect: (ChatContact) -> Void
    
    var contacts: [ChatContact] {
        guard let currentUser = auth.currentUser else { return [] }
        
        let relatedCases = firestore.cases
        
        if currentUser.role == .client {
            // Get unique lawyers from cases
            let lawyers = relatedCases.reduce(into: [String: ChatContact]()) { dict, c in
                if dict[c.lawyerId] == nil {
                    dict[c.lawyerId] = ChatContact(id: c.lawyerId, name: c.lawyerName, image: c.lawyerImage)
                }
            }
            return Array(lawyers.values).sorted { $0.name < $1.name }
        } else {
            // Get unique clients from cases
            let clients = relatedCases.reduce(into: [String: ChatContact]()) { dict, c in
                if dict[c.clientId] == nil {
                    dict[c.clientId] = ChatContact(id: c.clientId, name: c.clientName, image: c.clientImage)
                }
            }
            return Array(clients.values).sorted { $0.name < $1.name }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.lmBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 16) {
                            if contacts.isEmpty {
                                emptyState
                            } else {
                                ForEach(contacts) { contact in
                                    Button {
                                        onSelect(contact)
                                        dismiss()
                                    } label: {
                                        ContactCard(contact: contact)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(24)
                    }
                }
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let user = auth.currentUser {
                    firestore.listenForCases(role: user.role, userId: user.id)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 100)
            Image(systemName: "person.2.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.lmPrimary.opacity(0.1))
            
            Text("No Contacts Found")
                .font(.lmHeading)
                .foregroundColor(.lmPrimary)
            
            Text("You can only start chats with users related to your cases.")
                .font(.lmBody)
                .foregroundColor(.lmTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

private struct ContactCard: View {
    let contact: ChatContact
    
    var body: some View {
        HStack(spacing: 16) {
            LawMateAvatar(url: contact.image, name: contact.name, size: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.lmPrimary)
                
                Text("Start a conversation")
                    .font(.system(size: 13))
                    .foregroundColor(.lmTextSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.lmPrimary.opacity(0.3))
        }
        .padding(16)
        .background(Color.white.opacity(0.6))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
}

