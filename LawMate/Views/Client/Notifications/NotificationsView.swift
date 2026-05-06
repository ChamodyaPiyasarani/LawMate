import SwiftUI

struct NotificationModel: Identifiable, Hashable {
    let id = UUID()
    let iconInitials: String?
    let iconSystemName: String?
    let iconColor: Color
    let title: String
    let time: String
    let message: String
    let isUnread: Bool
}

struct NotificationsView: View {
    @Binding var navPath: NavigationPath
    @Binding var activeConversation: FBConversation?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firestore: FirestoreManager
    @EnvironmentObject var auth: AuthService
    @State private var showClearAlert = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: Custom Header
                LawMateNavigationBar(
                    title: "Notifications",
                    showBack: true,
                    onBack: { dismiss() },
                    trailingView: AnyView(
                        Group {
                            if !firestore.notifications.isEmpty {
                                Button {
                                    showClearAlert = true
                                } label: {
                                    Text("Clear All")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    )
                )
                .padding(.top, 20)
                .zIndex(10)
                
                if firestore.notifications.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "bell.slash")
                            .font(.system(size: 60))
                        Text("No notifications yet")
                            .font(.lmBody)
                            .foregroundColor(.lmTextSecondary)
                        Spacer()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            let (today, week, earlier) = groupedNotifications
                            
                            if !today.isEmpty {
                                NotificationSection(title: "Today", notifications: today, onTap: handleNotificationTap)
                            }
                            if !week.isEmpty {
                                NotificationSection(title: "This Week", notifications: week, onTap: handleNotificationTap)
                            }
                            if !earlier.isEmpty {
                                NotificationSection(title: "Earlier", notifications: earlier, onTap: handleNotificationTap)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 120)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("Clear All Notifications?", isPresented: $showClearAlert) {
            Button("Clear All", role: .destructive) {
                if let userId = auth.currentUser?.id {
                    firestore.clearAllNotifications(userId: userId)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your notifications. This action cannot be undone.")
        }
        .onAppear {
            if let user = AuthService.shared.currentUser {
                firestore.listenForNotifications(userId: user.id)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    firestore.markNotificationsAsRead(userId: user.id)
                }
            }
        }
    }
    
    private func handleNotificationTap(_ notification: FBNotification) {
        // Mark individual as read immediately
        if let userId = auth.currentUser?.id, let notificationId = notification.id {
            firestore.markNotificationAsRead(userId: userId, notificationId: notificationId)
        }
        
        let type = notification.type
        guard let relatedId = notification.relatedId else { return }
        
        switch type {
        case "message":
            if let conv = firestore.conversations.first(where: { $0.id == relatedId }) {
                activeConversation = conv
                dismiss() // Go back to messages view (or it will push if in Home)
            } else {
                ToastManager.shared.show(title: "Not Found", message: "This conversation is no longer available.", type: .error)
            }

        case "case":
            if let clientCase = firestore.cases.first(where: { $0.id == relatedId }) {
                navPath.append(clientCase)
                dismiss()
            } else {
                ToastManager.shared.show(title: "Not Found", message: "This case could not be found.", type: .error)
            }

        case "document":
            if let doc = firestore.advisoryDocuments.first(where: { $0.id == relatedId }) {
                navPath.append(doc)
                dismiss()
            } else {
                ToastManager.shared.show(title: "Not Found", message: "This document could not be found.", type: .error)
            }
            
        case "booking", "appointment":
            if let appointment = firestore.appointments.first(where: { $0.id == relatedId }) {
                navPath.append(appointment)
                dismiss()
            } else {
                ToastManager.shared.show(title: "Not Found", message: "This appointment could not be found.", type: .error)
            }
            
        default:
            print("Unhandled notification type: \(type)")
        }
    }
    
    private var groupedNotifications: ([FBNotification], [FBNotification], [FBNotification]) {
        let calendar = Calendar.current
        let now = Date()
        
        var today: [FBNotification] = []
        var week: [FBNotification] = []
        var earlier: [FBNotification] = []
        
        // Filter out chat messages — they should not appear in the notification UI list
        let filteredNotifications = firestore.notifications.filter { $0.type != "message" }
        
        for notification in filteredNotifications {
            if calendar.isDateInToday(notification.timestamp) {
                today.append(notification)
            } else if let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now), notification.timestamp > sevenDaysAgo {
                week.append(notification)
            } else {
                earlier.append(notification)
            }
        }
        return (today, week, earlier)
    }
}

// MARK: - Notification Section
struct NotificationSection: View {
    let title: String
    let notifications: [FBNotification]
    let onTap: (FBNotification) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.lmTextSecondary)
                .padding(.horizontal, 8)
            
            VStack(spacing: 0) {
                ForEach(Array(notifications.enumerated()), id: \.element.id) { index, item in
                    Button {
                        onTap(item)
                    } label: {
                        NotificationRow(notification: item)
                    }
                    .buttonStyle(.plain)
                    
                    if index < notifications.count - 1 {
                        Divider()
                            .padding(.leading, 70)
                            .padding(.trailing, 20)
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: FBNotification
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Unread Dot
            Circle()
                .fill(!notification.isRead ? Color.red : Color.clear)
                .frame(width: 8, height: 8)
                .padding(.top, 16)
            
            // Icon
            ZStack {
                Circle()
                    .fill(notification.dynamicColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: notification.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(notification.dynamicColor)
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(notification.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    Spacer()
                    
                    Text(timeAgo(notification.timestamp))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.lmTextSecondary)
                }
                
                Text(notification.body)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.lmTextSecondary.opacity(0.9))
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 16)
        .padding(.trailing, 16)
        .contentShape(Rectangle())
    }
    
    /* Dynamic properties moved to FBNotification model */
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NotificationsView(navPath: .constant(NavigationPath()), activeConversation: .constant(nil))
}
