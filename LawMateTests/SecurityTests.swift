import XCTest
import CryptoKit
@testable import LawMate

final class SecurityTests: XCTestCase {
    
    func testEncryptionDecryption() {
        let cryptoManager = MessageCryptoManager.shared
        let originalText = "Sensitive Legal Data"
        let conversationId = "test-conv-123"
        
        // Use the same key for testing encryption/decryption consistency
        let myPublicKey = cryptoManager.publicKeyBase64()
        
        guard let ciphertext = cryptoManager.encryptMessage(originalText, recipientPublicKeyBase64: myPublicKey, conversationId: conversationId) else {
            XCTFail("Encryption failed")
            return
        }
        
        XCTAssertNotEqual(originalText, ciphertext)
        
        guard let decryptedText = cryptoManager.decryptMessage(ciphertext, senderPublicKeyBase64: myPublicKey, conversationId: conversationId) else {
            XCTFail("Decryption failed")
            return
        }
        
        XCTAssertEqual(originalText, decryptedText)
    }
    
    func testKeychainCredentialsPersistence() {
        let keychain = KeychainManager.shared
        let testEmail = "test@lawyer.com"
        let testPass = "secure123"
        
        keychain.saveCredentials(email: testEmail, password: testPass)
        
        let retrieved = keychain.getCredentials()
        XCTAssertEqual(retrieved.email, testEmail)
        XCTAssertEqual(retrieved.password, testPass)
        
        keychain.clearCredentials()
        let cleared = keychain.getCredentials()
        XCTAssertNil(cleared.email)
        XCTAssertNil(cleared.password)
    }
}
