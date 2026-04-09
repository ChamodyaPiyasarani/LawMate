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
    @Environment(\.dismiss) private var dismiss
    
    let todayAlerts = [
        NotificationModel(iconInitials: "SM", iconSystemName: nil, iconColor: .teal, title: "Sarah Mitchell, Esq.", time: "25 min ago", message: "Your case documents for Johnson v. Smith have been filed with the court. Please review the confirmation.", isUnread: true),
        NotificationModel(iconInitials: nil, iconSystemName: "building.columns.fill", iconColor: .lmPrimary, title: "Lawmate Team", time: "2h ago", message: "Reminder: Your consultation with Atty. David Park is scheduled for tomorrow at 2:00 PM.", isUnread: true)
    ]
    
    let weekAlerts = [
        NotificationModel(iconInitials: "DP", iconSystemName: nil, iconColor: .blue, title: "David Park, Esq.", time: "Yesterday", message: "I've reviewed the settlement offer. Let's discuss your options — I recommend we schedule a call.", isUnread: false),
        NotificationModel(iconInitials: nil, iconSystemName: "list.clipboard.fill", iconColor: .lmPrimary, title: "Lawmate Billing", time: "2 days ago", message: "Invoice #LM-4821 for legal services ($1,250.00) is now available. Payment due by April 15.", isUnread: false),
        NotificationModel(iconInitials: "SM", iconSystemName: nil, iconColor: .teal, title: "Sarah Mitchell, Esq.", time: "3 days ago", message: "New evidence has been submitted by the opposing counsel. I'll prepare our response by Friday.", isUnread: true)
    ]
    
    let earlierAlerts = [
        NotificationModel(iconInitials: "MC", iconSystemName: nil, iconColor: .purple, title: "Maria Chen, Paralegal", time: "Mar 25", message: "Please sign the attached affidavit and return it at your earliest convenience.", isUnread: false)
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Green blob top-left
            GreenBlobBackground(style: .client)
                .frame(height: 300)
            
            VStack(spacing: 0) {
                // MARK: Custom Header
                LawMateNavigationBar(
                    title: "Notifications",
                    showBack: true,
                    showNotification: false,
                    onBack: { dismiss() }
                )
                .padding(.top, 64)
                .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        NotificationSection(title: "Today", notifications: todayAlerts)
                        NotificationSection(title: "This Week", notifications: weekAlerts)
                        NotificationSection(title: "Earlier", notifications: earlierAlerts)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 120)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Notification Section
struct NotificationSection: View {
    let title: String
    let notifications: [NotificationModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.lmTextSecondary)
                .padding(.horizontal, 8)
            
            VStack(spacing: 0) {
                ForEach(Array(notifications.enumerated()), id: \.offset) { index, item in
                    NotificationRow(notification: item)
                    
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
    let notification: NotificationModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Unread Dot
            Circle()
                .fill(notification.isUnread ? Color.green : Color.clear)
                .frame(width: 8, height: 8)
                .padding(.top, 16)
            
            // Icon
            ZStack {
                Circle()
                    .fill(notification.iconColor)
                    .frame(width: 44, height: 44)
                
                if let initials = notification.iconInitials {
                    Text(initials)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                } else if let iconName = notification.iconSystemName {
                    Image(systemName: iconName)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(notification.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    Spacer()
                    
                    Text(notification.time)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.lmTextSecondary)
                }
                
                Text(notification.message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.lmTextSecondary.opacity(0.9))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 16)
        .padding(.trailing, 16)
    }
}

#Preview {
    NotificationsView()
}
