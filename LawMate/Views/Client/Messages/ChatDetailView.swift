import SwiftUI

struct ChatMessage: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let time: String
    let isMe: Bool
}

struct ChatDetailView: View {
    let chat: ChatPreview
    @Environment(\.dismiss) private var dismiss
    @State private var messageText: String = ""
    
    let mockMessages = [
        ChatMessage(text: "Good morning Emily. I wanted to update you on the discovery process.", time: "9:30 AM", isMe: false),
        ChatMessage(text: "We received the documents from the opposing counsel yesterday.", time: "9:31 AM", isMe: false),
        ChatMessage(text: "That's great news! Were there any surprises?", time: "9:35 AM", isMe: true),
        ChatMessage(text: "Nothing unexpected. I'll prepare a summary for our meeting next week.", time: "9:38 AM", isMe: false),
        ChatMessage(text: "Perfect, thank you for the update!", time: "9:41 AM", isMe: true)
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Green blob top-left
            GreenBlobBackground(style: .client)
                .frame(height: 300)
            
            VStack(spacing: 0) {
                // MARK: Chat Header
                chatHeader
                    .padding(.horizontal, 24)
                    .padding(.top, 64)
                    .padding(.bottom, 20)
                    .zIndex(10)
                
                // MARK: Messages List
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Date Separator
                        Text("Today")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.04))
                            .clipShape(Capsule())
                            .padding(.vertical, 8)
                        
                        ForEach(mockMessages) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100) // Padding for input area
                }
            }
            .ignoresSafeArea(edges: .top)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            
            // MARK: Input Area
            VStack {
                Spacer()
                
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $messageText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.lmTextPrimary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    
                    Button(action: {
                        // Send action
                        messageText = ""
                    }) {
                        Circle()
                            .fill(Color.lmPrimary)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    .padding(.trailing, 8)
                }
                .background(Color.white.opacity(0.8))
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 24)
                .padding(.bottom, 30) // Floating above bottom edge
                .background(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.lmBackground, Color.lmBackground.opacity(0)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: 140)
                        .offset(y: 20)
                        .allowsHitTesting(false)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
            // Safely removing .ignoresSafeArea(edges: .bottom) here allows keyboard to push it up!
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Header
    private var chatHeader: some View {
        HStack(spacing: 16) {
            // Back Button
            LawMateBackButton(action: { dismiss() })
            
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.lmPrimary.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Text(chat.partnerInitials)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lmPrimary)
                
                if chat.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.lmBackground, lineWidth: 2))
                        .offset(x: -2, y: -2)
                }
            }
            
            // Name Info
            VStack(alignment: .leading, spacing: 2) {
                Text(chat.partnerName)
                    .font(.lmHeading)
                    .foregroundColor(.lmPrimary)
                
                Text(chat.isOnline ? "Online" : "Offline")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.lmTextSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Message Bubble Component
struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isMe {
                Spacer(minLength: 40)
            }
            
            VStack(alignment: message.isMe ? .trailing : .leading, spacing: 6) {
                Text(message.text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(message.isMe ? .white : .lmTextPrimary)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(message.isMe ? Color.lmPrimary.opacity(0.85) : Color.white)
                    .clipShape(BubbleShape(isMe: message.isMe))
                    .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
                
                Text(message.time)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.lmTextSecondary)
                    .padding(.horizontal, 6)
            }
            
            if !message.isMe {
                Spacer(minLength: 40)
            }
        }
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
    ChatDetailView(chat: ChatPreview(
        id: "1",
        partnerName: "Nimal Perera",
        partnerInitials: "NP",
        lastMessageTime: "9:41 AM",
        lastMessage: "I've reviewed the documents...",
        unreadCount: 2,
        isOnline: true
    ))
}
