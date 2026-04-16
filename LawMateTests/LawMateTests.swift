import XCTest
@testable import LawMate

final class LawMateTests: XCTestCase {

    func testUserInitialization() {
        let user = User(fullName: "Test User", email: "test@example.com", role: .client)
        XCTAssertEqual(user.fullName, "Test User")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.role, .client)
    }
    
    func testLegalCaseProgress() {
        var stages = [
            CaseStage(title: "Stage 1", description: "Desc 1", isCompleted: true),
            CaseStage(title: "Stage 2", description: "Desc 2", isCompleted: false)
        ]
        
        let legalCase = LegalCase(
            id: "1", 
            caseNumber: "C1", 
            title: "Test Case", 
            clientName: "Client", 
            type: "Civil", 
            status: "Active", 
            priority: "High", 
            lawyerName: "Lawyer", 
            createdDate: Date(), 
            stages: stages, 
            documents: []
        )
        
        XCTAssertEqual(legalCase.completedStagesCount, 1)
        XCTAssertEqual(legalCase.progressProgress, 0.5)
    }

    func testNotificationManagerSingleton() {
        let manager = NotificationManager.shared
        XCTAssertNotNil(manager)
    }
    
    func testAuthServiceMockLogin() {
        let service = AuthService.shared
        service.login(email: "test@example.com", role: .lawyer)
        XCTAssertTrue(service.isAuthenticated)
        XCTAssertEqual(service.currentUser?.role, .lawyer)
        
        service.logout()
        XCTAssertFalse(service.isAuthenticated)
        XCTAssertNil(service.currentUser)
    }
}
