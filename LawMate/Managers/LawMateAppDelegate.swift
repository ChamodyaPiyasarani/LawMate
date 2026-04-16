import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class LawMateAppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Firebase configuration
        FirebaseApp.configure()
        
        // UNUserNotificationCenter setup
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        
        // Messaging setup
        Messaging.messaging().delegate = self
        
        // Request authorization and register for remote notifications
        NotificationManager.shared.requestPermission()
        application.registerForRemoteNotifications()
        
        return true
    }
    
    // Remote notifications callbacks
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Pass device token to Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
}

// MARK: - MessagingDelegate
extension LawMateAppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        guard let fcmToken = fcmToken else { return }
        
        // Notify the app that a new token is available
        NotificationCenter.default.post(
            name: .fcmTokenNotification,
            object: nil,
            userInfo: ["token": fcmToken]
        )
        
        // Update user's token if they are already logged in
        AuthService.shared.updateFCMToken(fcmToken)
    }
}

// Helper notification name
extension Notification.Name {
    static let fcmTokenNotification = Notification.Name("fcmTokenNotification")
}
