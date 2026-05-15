import XCTest
import EventKit
@testable import LawMate

final class EventKitManagerTests: XCTestCase {
    
    var eventKitManager: EventKitManager!
    
    override func setUp() {
        super.setUp()
        eventKitManager = EventKitManager.shared
    }
    
    override func tearDown() {
        eventKitManager = nil
        super.tearDown()
    }
    
    func testAuthorizationStatus() {
        // This is a system-wide status, so we just check if it's accessible
        let status = eventKitManager.authorizationStatus
        XCTAssertNotNil(status)
    }
    
    // Note: createEvent and removeEvent are difficult to test without a mock EKEventStore
    // or being in a controlled environment with pre-granted permissions.
}
