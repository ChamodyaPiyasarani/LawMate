import XCTest
import SwiftUI
@testable import LawMate

final class AccessibilityManagerTests: XCTestCase {
    
    var accessibilityManager: AccessibilityManager!
    
    override func setUp() {
        super.setUp()
        accessibilityManager = AccessibilityManager.shared
    }
    
    override func tearDown() {
        accessibilityManager = nil
        super.tearDown()
    }
    
    func testDynamicTypeSizeConversion() {
        accessibilityManager.textScale = 1.0
        XCTAssertEqual(accessibilityManager.dynamicTypeSize, .large)
        
        accessibilityManager.textScale = 1.2
        XCTAssertEqual(accessibilityManager.dynamicTypeSize, .xxLarge)
        
        accessibilityManager.textScale = 1.5
        XCTAssertEqual(accessibilityManager.dynamicTypeSize, .xxxLarge)
        
        accessibilityManager.textScale = 1.6
        XCTAssertEqual(accessibilityManager.dynamicTypeSize, .accessibility1)
        
        accessibilityManager.textScale = 2.0
        XCTAssertEqual(accessibilityManager.dynamicTypeSize, .accessibility3)
    }
    
    func testEffectiveSettings() {
        accessibilityManager.highContrast = false
        accessibilityManager.systemHighContrast = false
        XCTAssertFalse(accessibilityManager.effectiveHighContrast)
        
        accessibilityManager.highContrast = true
        XCTAssertTrue(accessibilityManager.effectiveHighContrast)
        
        accessibilityManager.highContrast = false
        accessibilityManager.systemHighContrast = true
        XCTAssertTrue(accessibilityManager.effectiveHighContrast)
    }
}
