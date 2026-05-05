import Foundation
import CryptoKit

final class MessageCryptoManager {
    static let shared = MessageCryptoManager()

    private let privateKeyKey = "messagePrivateKey"

    private init() {}

    func publicKeyBase64() -> String {
        let privateKey = loadOrCreatePrivateKey()
        let publicKey = privateKey.publicKey
        return publicKey.rawRepresentation.base64EncodedString()
    }

    func encryptMessage(_ text: String, recipientPublicKeyBase64: String, conversationId: String) -> String? {
        guard let recipientKeyData = Data(base64Encoded: recipientPublicKeyBase64) else { return nil }

        do {
            let recipientPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: recipientKeyData)
            let sharedSecret = try loadOrCreatePrivateKey().sharedSecretFromKeyAgreement(with: recipientPublicKey)
            let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
                using: SHA256.self,
                salt: Data(conversationId.utf8),
                sharedInfo: Data(),
                outputByteCount: 32
            )

            let messageData = Data(text.utf8)
            let sealedBox = try AES.GCM.seal(messageData, using: symmetricKey)
            guard let combined = sealedBox.combined else { return nil }
            return combined.base64EncodedString()
        } catch {
            print("Message encryption failed: \(error)")
            return nil
        }
    }

    func decryptMessage(_ ciphertextBase64: String, senderPublicKeyBase64: String, conversationId: String) -> String? {
        guard let senderKeyData = Data(base64Encoded: senderPublicKeyBase64),
              let combinedData = Data(base64Encoded: ciphertextBase64) else { return nil }

        do {
            let senderPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: senderKeyData)
            let sharedSecret = try loadOrCreatePrivateKey().sharedSecretFromKeyAgreement(with: senderPublicKey)
            let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
                using: SHA256.self,
                salt: Data(conversationId.utf8),
                sharedInfo: Data(),
                outputByteCount: 32
            )

            let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
            let decrypted = try AES.GCM.open(sealedBox, using: symmetricKey)
            return String(data: decrypted, encoding: .utf8)
        } catch {
            print("Message decryption failed: \(error)")
            return nil
        }
    }

    private func loadOrCreatePrivateKey() -> Curve25519.KeyAgreement.PrivateKey {
        if let data = KeychainManager.shared.getData(key: privateKeyKey),
           let privateKey = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data) {
            return privateKey
        }

        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        KeychainManager.shared.saveData(key: privateKeyKey, data: privateKey.rawRepresentation)
        return privateKey
    }
}
