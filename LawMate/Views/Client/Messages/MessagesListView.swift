import SwiftUI

struct ChatPreview: Identifiable, Hashable {
    let id: String
    let partnerName: String
    let partnerInitials: String
    let lastMessageTime: String
    let lastMessage: String
    let unreadCount: Int
    let isOnline: Bool
}

struct MessagesListView: View {
    var onBack: () -> Void = {}
    
    let mockChats = [
        ChatPreview(
            id: "1",
            partnerName: "Nimal Perera",
            partnerInitials: "NP",
            lastMessageTime: "9:41 AM",
            lastMessage: "I've reviewed the documents...",
            unreadCount: 2,
            isOnline: true
        ),
        ChatPreview(
            id: "2",
            partnerName: "Sanduni Fernando",
            partnerInitials: "SF",
            lastMessageTime: "Yesterday",
            lastMessage: "Your next appointment is...",
            unreadCount: 0,
            isOnline: false
        )
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Green blob top-left
            GreenBlobBackground(style: .client)
                .frame(height: 300)
            
            VStack(spacing: 0) {
                // MARK: Left-Aligned Header
                HStack(alignment: .center) {
                    Text("Chat")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    Spacer()
                    
                    NotificationButton(badgeCount: 3, action: {})
                }
                .padding(.horizontal, 24)
                .padding(.top, 64)
                .padding(.bottom, 24)
                .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(mockChats) { chat in
                            NavigationLink(value: chat) {
                                ChatPreviewCard(chat: chat)
                            }
                            .buttonStyle(.plain)
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
    }
}

// MARK: - Chat Preview Card
struct ChatPreviewCard: View {
    let chat: ChatPreview
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar Placeholder
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.lmPrimary.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Text(chat.partnerInitials)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.lmPrimary)
                
                if chat.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: -2, y: -2)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(chat.partnerName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    Spacer()
                    
                    Text(chat.lastMessageTime)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.lmPrimary)
                }
                
                HStack {
                    Text(chat.lastMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.lmTextSecondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if chat.unreadCount > 0 {
                        Circle()
                            .fill(Color.lmPrimary)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text("\(chat.unreadCount)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            )
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
}

#Preview {
    MessagesListView()
}
