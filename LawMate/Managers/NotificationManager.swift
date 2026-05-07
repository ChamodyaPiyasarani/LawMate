import Foundation
import UserNotifications
import UIKit

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    // For Deep Linking
    enum DeepLinkRoute: Hashable {
        case chat(conversationId: String)
        case notificationCenter
        case myCases
        case appointment(appointmentId: String)
        case lawyerProfile(lawyerId: String)
    }
    @Published var pendingRoute: DeepLinkRoute? = nil
    @Published var showNotifications = false
    
    override init() {
        super.init()
        checkStatus()
    }
    
    func checkStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                if let error = error {
                    print("Error requesting notification permission: \(error)")
                }
            }
        }
    }
    
    func scheduleNotification(title: String, body: String, relatedId: String? = nil, type: String? = nil, timeInterval: TimeInterval = 1) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        var userInfo: [String: Any] = [:]
        if let relatedId = relatedId { userInfo["relatedId"] = relatedId }
        if let type = type { userInfo["type"] = type }
        content.userInfo = userInfo
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, timeInterval), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling local notification: \(error)")
            }
        }
    }
    
    func scheduleAppointmentReminder(for appointment: FBAppointment) {
        guard let startTime = appointment.startTime, startTime > Date() else { return }
        guard let appointmentId = appointment.id else { return }
        
        // Reminder 30 minutes before
        let reminderTime = startTime.addingTimeInterval(-30 * 60)
        
        // If it's already less than 30 mins away, don't schedule or schedule immediately if appropriate
        // Here we'll only schedule if it's at least 1 minute in the future
        guard reminderTime > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Appointment Reminder"
        content.body = "You have an appointment with \(appointment.lawyerName) at \(appointment.time)."
        content.sound = .default
        content.userInfo = ["type": "appointment", "relatedId": appointmentId]
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Use appointment ID as part of identifier to avoid duplicates
        let identifier = "reminder_\(appointmentId)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling appointment reminder: \(error)")
            } else {
                print("Scheduled reminder for appointment \(appointmentId) at \(reminderTime)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    
    // Receive notification while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        print("Received foreground notification: \(userInfo)")
        
        // You can customize behavior here based on payload
        completionHandler([[.banner, .sound, .list]])
    }
    
    // Handle user tapping the notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        print("Tapped notification with userInfo: \(userInfo)")
        
        let type = userInfo["type"] as? String
        let relatedId = userInfo["relatedId"] as? String
        
        DispatchQueue.main.async {
            if type == "appointment" || type == "booking", let id = relatedId {
                self.pendingRoute = .appointment(appointmentId: id)
            } else if type == "chat" || type == "message", let id = relatedId {
                self.pendingRoute = .chat(conversationId: id)
            } else if type == "case" {
                self.pendingRoute = .myCases
            } else if type == "lawyer_profile", let id = relatedId {
                self.pendingRoute = .lawyerProfile(lawyerId: id)
            } else {
                self.pendingRoute = .notificationCenter
            }
        }
        
        completionHandler()
    }
}
