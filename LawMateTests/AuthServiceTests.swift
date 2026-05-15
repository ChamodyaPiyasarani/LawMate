import XCTest
@testable import LawMate

final class AuthServiceTests: XCTestCase {
    
    var authService: AuthService!
    
    override func setUp() {
        super.setUp()
        authService = AuthService.shared
    }
    
    override func tearDown() {
        authService.logout()
        authService = nil
        super.tearDown()
    }
    
    func testLoginForTesting() {
        let testEmail = "test@lawmate.com"
        let testRole = UserRole.lawyer
        
        authService.loginForTesting(email: testEmail, role: testRole)
        
        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertEqual(authService.currentUser?.email, testEmail)
        XCTAssertEqual(authService.currentUser?.role, testRole)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "isLoggedIn"))
    }
    
    func testLogout() {
        authService.loginForTesting(email: "test@lawmate.com", role: .client)
        XCTAssertTrue(authService.isAuthenticated)
        
        authService.logout()
        
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertNil(authService.currentUser)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "isLoggedIn"))
        XCTAssertNil(UserDefaults.standard.string(forKey: "userRole"))
    }
    
    func testOptionalStringIsNilOrEmpty() {
        let nilString: String? = nil
        let emptyString: String? = ""
        let nonEmptyString: String? = "Hello"
        
        XCTAssertTrue(nilString.isNilOrEmpty)
        XCTAssertTrue(emptyString.isNilOrEmpty)
        XCTAssertFalse(nonEmptyString.isNilOrEmpty)
    }
}
