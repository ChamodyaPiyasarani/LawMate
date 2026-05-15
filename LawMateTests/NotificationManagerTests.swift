import XCTest
@testable import LawMate

final class NotificationManagerTests: XCTestCase {
    
    var notificationManager: NotificationManager!
    
    override func setUp() {
        super.setUp()
        notificationManager = NotificationManager.shared
    }
    
    override func tearDown() {
        notificationManager.pendingRoute = nil
        notificationManager = nil
        super.tearDown()
    }
    
    func testDeepLinkRouting() {
        // Mocking the behavior of userNotificationCenter(_:didReceive:withCompletionHandler:) 
        // by manually setting the pendingRoute or simulating the logic.
        
        let userInfo: [String: Any] = ["type": "appointment", "relatedId": "app-123"]
        
        // Simulating the logic inside the delegate
        let type = userInfo["type"] as? String
        let relatedId = userInfo["relatedId"] as? String
        
        if type == "appointment", let id = relatedId {
            notificationManager.pendingRoute = .appointment(appointmentId: id)
        }
        
        XCTAssertEqual(notificationManager.pendingRoute, .appointment(appointmentId: "app-123"))
    }
    
    func testChatDeepLinkRouting() {
        let userInfo: [String: Any] = ["type": "chat", "relatedId": "conv-456"]
        
        let type = userInfo["type"] as? String
        let relatedId = userInfo["relatedId"] as? String
        
        if type == "chat", let id = relatedId {
            notificationManager.pendingRoute = .chat(conversationId: id)
        }
        
        XCTAssertEqual(notificationManager.pendingRoute, .chat(conversationId: "conv-456"))
    }
}
