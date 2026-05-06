import SwiftUI

struct ChatMessage: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let time: String
    let isMe: Bool
}

struct ChatDetailView: View {
    let conversation: FBConversation
    @Environment(\.dismiss) private var dismiss
    @State private var messageText: String = ""
    @EnvironmentObject var firestore: FirestoreManager
    @EnvironmentObject var auth: AuthService

    private var validConversationId: String? {
        let trimmed = conversation.id?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty ?? true) ? nil : trimmed
    }
    
    var partner: (id: String, name: String, image: String?) {
        conversation.partnerInfo(for: auth.currentUser?.id ?? "")
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // blob style based on role
            GreenBlobBackground(style: auth.currentUser?.role == .lawyer ? .lawyer : .client)
                .frame(height: 300)
            
            VStack(spacing: 0) {
                // MARK: Chat Header
                chatHeader
                    .padding(.horizontal, 24)
                    .padding(.top, 65)
                    .padding(.bottom, 20)
                    .zIndex(10)
                
                // MARK: Messages List
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            if validConversationId == nil {
                                invalidState
                            } else if firestore.messages.isEmpty {
                                emptyState
                            } else {
                                ForEach(firestore.messages) { message in
                                    MessageBubble(message: message, currentUserId: auth.currentUser?.id ?? "")
                                        .id(message.id)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 120) // Padding for input area
                    }
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .onChange(of: firestore.messages) { _, _ in
                        if let lastId = firestore.messages.last?.id {
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                    // Scroll to bottom on first load
                    .onAppear {
                        if let lastId = firestore.messages.last?.id {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
            
            // MARK: Input Area — floats above keyboard
            VStack {
                Spacer()
                
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $messageText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.lmTextPrimary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .submitLabel(.send)
                        .onSubmit { sendCurrentMessage() }
                    
                    Button(action: {
                        sendCurrentMessage()
                    }) {
                        Circle()
                            .fill(messageText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.lmTextSecondary.opacity(0.3) : Color.lmPrimary)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.trailing, 8)
                }
                .background(Color.white.opacity(0.95))
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: -4)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if let conversationId = validConversationId {
                firestore.listenForMessages(conversationId: conversationId)
                if let userId = auth.currentUser?.id {
                    firestore.markConversationAsRead(id: conversationId, userId: userId)
                }
            }
        }
        .onDisappear {
            firestore.stopListeningForMessages()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 100)
            Text("No messages yet")
                .font(.lmHeading)
                .foregroundColor(.lmPrimary.opacity(0.3))
            Text("Send a message to start the conversation.")
                .font(.lmCaption)
                .foregroundColor(.lmTextSecondary)
        }
    }

    private var invalidState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 100)
            Text("Chat unavailable")
                .font(.lmHeading)
                .foregroundColor(.lmPrimary.opacity(0.4))
            Text("This conversation could not be loaded. Please try again.")
                .font(.lmCaption)
                .foregroundColor(.lmTextSecondary)
                .multilineTextAlignment(.center)
            Button("Go Back") {
                dismiss()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.lmPrimary)
            .padding(.top, 4)
        }
    }
    
    private func sendCurrentMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard let conversationId = validConversationId, let userId = auth.currentUser?.id else { return }
        
        firestore.sendMessage(to: conversationId, text: messageText, senderId: userId)
        messageText = ""
    }
    
    // MARK: - Header
    private var chatHeader: some View {
        HStack(spacing: 16) {
            // Back Button
            LawMateBackButton(action: { dismiss() })
            
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                LawMateAvatar(url: partner.image, name: partner.name, size: 44)
                
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color.lmBackground, lineWidth: 2))
                    .offset(x: -2, y: -2)
            }
            
            // Name Info
            VStack(alignment: .leading, spacing: 2) {
                Text(partner.name)
                    .font(.lmHeading)
                    .foregroundColor(.lmPrimary)
                
                Text("Online")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.lmTextSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Message Bubble Component
struct MessageBubble: View {
    let message: FBMessage
    let currentUserId: String
    
    var isMe: Bool {
        message.senderId == currentUserId
    }
    
    var body: some View {
        HStack {
            if isMe {
                Spacer(minLength: 40)
            }
            
            VStack(alignment: isMe ? .trailing : .leading, spacing: 6) {
                Text(message.text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isMe ? .white : .lmTextPrimary)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(isMe ? Color.lmPrimary.opacity(0.85) : Color.white)
                    .clipShape(BubbleShape(isMe: isMe))
                    .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
                
                Text(formatTime(message.timestamp))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.lmTextSecondary)
                    .padding(.horizontal, 6)
            }
            
            if !isMe {
                Spacer(minLength: 40)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}


// Custom shape for chat bubbles
struct BubbleShape: Shape {
    let isMe: Bool
    
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 20
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [
                .topLeft,
                .topRight,
                isMe ? .bottomLeft : .bottomRight
            ],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ChatDetailView(conversation: FBConversation(
        participants: ["U1", "U2"],
        lastMessage: "I've reviewed the documents...",
        lastMessageAt: Date(),
        memberNames: ["U1": "Emily", "U2": "Nimal Perera"],
        memberImages: ["U1": nil, "U2": nil]
    ))
}
