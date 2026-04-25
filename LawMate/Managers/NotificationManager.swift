import Foundation
import UserNotifications
import UIKit

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    // For Deep Linking
    enum DeepLinkRoute: Hashable {
        case chat(conversationId: String)
        case notificationCenter // to go to the notifications tab
        case myCases
    }
    @Published var pendingRoute: DeepLinkRoute? = nil
    
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
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling local notification: \(error)")
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
        
        DispatchQueue.main.async {
            self.pendingRoute = .notificationCenter
        }
        
        completionHandler()
    }
}
