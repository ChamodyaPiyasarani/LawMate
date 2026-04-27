import SwiftUI


struct MessagesListView: View {
    var onBack: () -> Void = {}
    var onSelect: (FBConversation) -> Void = { _ in }
    
    @State private var showingNewChatSheet = false
    @EnvironmentObject var firestore: FirestoreManager
    @EnvironmentObject var auth: AuthService
    
    // Delete state
    @State private var conversationToDelete: FBConversation? = nil
    @State private var showDeleteAlert = false
    /// IDs hidden from UI immediately on delete (before Firestore confirms)
    @State private var locallyDeletedIds: Set<String> = []
    
    private var sortedConversations: [FBConversation] {
        firestore.conversations.filter { conv in
            guard let id = conv.id else { return true }
            return !locallyDeletedIds.contains(id)
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // blob style based on role
            GreenBlobBackground(style: auth.currentUser?.role == .lawyer ? .lawyer : .client)
                .frame(height: 300)
            
            VStack(spacing: 0) {
                // MARK: Header
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
                    VStack(spacing: 12) {
                        if sortedConversations.isEmpty {
                            emptyState
                        } else {
                            ForEach(sortedConversations) { conversation in
                                ChatPreviewCard(
                                    conversation: conversation,
                                    onTap: { onSelect(conversation) },
                                    onDeleteRequest: {
                                        conversationToDelete = conversation
                                        showDeleteAlert = true
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
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
                
                firestore.getOrCreateConversation(
                    between: currentUser.id,
                    and: contact.id,
                    partnerInfo: (name: contact.name, image: contact.image),
                    currentUser: currentUser
                ) { conversationId in
                    // Small delay to ensure sheet dismissal completes before navigation starts
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let existing = firestore.conversations.first(where: { $0.id == conversationId }) {
                            onSelect(existing)
                        } else {
                            let memberNames = [currentUser.id: currentUser.fullName, contact.id: contact.name]
                            let memberImages: [String: String?] = [currentUser.id: currentUser.profileImage, contact.id: contact.image]
                            
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
        .alert("Delete Conversation", isPresented: $showDeleteAlert, presenting: conversationToDelete) { conv in
            Button("Delete", role: .destructive) {
                guard let id = conv.id else {
                    print("DEBUG: Delete failed in view - conversation ID is nil")
                    conversationToDelete = nil
                    return
                }
                print("DEBUG: Delete pressed in view for id: \(id)")
                conversationToDelete = nil
                // Immediately hide from UI — works regardless of Firestore timing
                locallyDeletedIds.insert(id)
                
                firestore.deleteConversation(id: id) { success in
                    if !success {
                        print("DEBUG: Delete failed in Firestore, rolling back UI for id: \(id)")
                        // Rollback: show conversation again if delete failed
                        locallyDeletedIds.remove(id)
                        ToastManager.shared.show(title: "Error", message: "Could not delete the conversation.", type: .error)
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                conversationToDelete = nil
            }
        } message: { conv in
            let partner = conv.partnerInfo(for: auth.currentUser?.id ?? "")
            Text("Are you sure you want to permanently delete your conversation with \(partner.name)? This cannot be undone.")
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 80)
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 52))
                .foregroundColor(.lmPrimary.opacity(0.1))
            Text("No Conversations Yet")
                .font(.lmHeading)
                .foregroundColor(.lmPrimary.opacity(0.5))
            Text("Tap the + button to start a new chat.")
                .font(.lmCaption)
                .foregroundColor(.lmTextSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Chat Preview Card
struct ChatPreviewCard: View {
    let conversation: FBConversation
    var onTap: () -> Void
    var onDeleteRequest: () -> Void
    
    @EnvironmentObject var auth: AuthService
    
    var body: some View {
        let partner = conversation.partnerInfo(for: auth.currentUser?.id ?? "")
        let userId = auth.currentUser?.id ?? ""
        let unreadCount = conversation.unreadCounts?[userId] ?? 0
        let hasUnread = unreadCount > 0
        
        ZStack(alignment: .trailing) {
            // Main Button Area
            Button(action: onTap) {
                HStack(spacing: 14) {
                    // MARK: Avatar with online dot
                    ZStack(alignment: .bottomTrailing) {
                        LawMateAvatar(url: partner.image, name: partner.name, size: 54)
                        
                        Circle()
                            .fill(Color.green)
                            .frame(width: 13, height: 13)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .offset(x: -2, y: -2)
                    }
                    
                    // MARK: Text Content
                    VStack(alignment: .leading, spacing: 5) {
                        Text(partner.name)
                            .font(.system(size: 15, weight: hasUnread ? .bold : .semibold))
                            .foregroundColor(.lmPrimary)
                            .lineLimit(1)
                        
                        Text(conversation.lastMessage ?? "Start a conversation")
                            .font(.system(size: 13, weight: hasUnread ? .medium : .regular))
                            .foregroundColor(hasUnread ? .lmPrimary.opacity(0.7) : .lmTextSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // MARK: Right side — date + unread badge
                    VStack(alignment: .trailing, spacing: 6) {
                        if let date = conversation.lastMessageAt {
                            Text(formatDate(date))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(hasUnread ? .lmPrimary : .lmTextSecondary)
                        }
                        
                        if hasUnread {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 20, height: 20)
                                Text("\(min(unreadCount, 99))")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        } else {
                            Color.clear.frame(width: 20, height: 20)
                        }
                    }
                    .padding(.trailing, 32) // Space for the floating ellipsis
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(hasUnread ? Color.lmPrimary.opacity(0.04) : Color.white.opacity(0.65))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(hasUnread ? Color.lmPrimary.opacity(0.15) : Color.white.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            // MARK: Ellipsis Menu (Separate Hit Target)
            Menu {
                Button(role: .destructive) {
                    onDeleteRequest()
                } label: {
                    Label("Delete Conversation", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.lmTextSecondary)
                    .frame(width: 44, height: 44) // Generous hit target
                    .contentShape(Rectangle())
            }
            .padding(.trailing, 8)
            .buttonStyle(.plain)
        }
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
        }
        return formatter.string(from: date)
    }
}

// MARK: - New Chat Selection
struct ChatContact: Identifiable {
    let id: String
    let name: String
    let image: String?
}

struct NewChatSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firestore: FirestoreManager
    @EnvironmentObject var auth: AuthService
    
    var onSelect: (ChatContact) -> Void
    
    var contacts: [ChatContact] {
        guard let currentUser = auth.currentUser else { return [] }
        
        let relatedCases = firestore.cases
        
        if currentUser.role == .client {
            let lawyers = relatedCases.reduce(into: [String: ChatContact]()) { dict, c in
                if dict[c.lawyerId] == nil {
                    dict[c.lawyerId] = ChatContact(id: c.lawyerId, name: c.lawyerName, image: c.lawyerImage)
                }
            }
            return Array(lawyers.values).sorted { $0.name < $1.name }
        } else {
            let clients = relatedCases.reduce(into: [String: ChatContact]()) { dict, c in
                if dict[c.clientId] == nil {
                    dict[c.clientId] = ChatContact(id: c.clientId, name: c.clientName, image: c.clientImage)
                }
            }
            return Array(clients.values).sorted { $0.name < $1.name }
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                LawMateNavigationBar(
                    title: "New Chat",
                    showBack: true,
                    onBack: { dismiss() }
                )
                .padding(.top, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
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
        .onAppear {
            if let user = auth.currentUser {
                firestore.listenForCases(role: user.role, userId: user.id)
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

#Preview {
    MessagesListView()
}
