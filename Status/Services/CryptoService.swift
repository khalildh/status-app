import Foundation
import CryptoKit
@preconcurrency import FirebaseFirestore

@MainActor
@Observable
final class CryptoService {
    @ObservationIgnored private var _db: Firestore?
    private var db: Firestore { if _db == nil { _db = Firestore.firestore() }; return _db! }

    // Local key pair stored in Keychain
    @ObservationIgnored private var privateKey: P256.KeyAgreement.PrivateKey?

    // Cache of shared secrets with other users
    @ObservationIgnored private var sharedSecrets: [String: SymmetricKey] = [:]

    // MARK: - Key Management

    /// Generate or load the user's key pair. Called once at login.
    func initialize(userId: String) async throws {
        if let existingKey = loadPrivateKey(userId: userId) {
            privateKey = existingKey
        } else {
            let newKey = P256.KeyAgreement.PrivateKey()
            privateKey = newKey
            savePrivateKey(newKey, userId: userId)
        }

        // Publish public key to Firestore
        guard let privateKey else { return }
        let publicKeyData = privateKey.publicKey.rawRepresentation.base64EncodedString()
        try await db.collection("users").document(userId).updateData([
            "publicKey": publicKeyData
        ])
    }

    // MARK: - Encrypt / Decrypt

    func encrypt(_ plaintext: String, for recipientId: String) async throws -> EncryptedMessage {
        let sharedSecret = try await getSharedSecret(with: recipientId)
        let data = Data(plaintext.utf8)
        let nonce = AES.GCM.Nonce()
        let sealed = try AES.GCM.seal(data, using: sharedSecret, nonce: nonce)

        guard let combined = sealed.combined else {
            throw CryptoError.encryptionFailed
        }

        return EncryptedMessage(
            ciphertext: combined.base64EncodedString(),
            isEncrypted: true
        )
    }

    func decrypt(_ encrypted: EncryptedMessage, from senderId: String) async throws -> String {
        guard encrypted.isEncrypted else {
            return encrypted.ciphertext // Plain text fallback
        }

        guard let data = Data(base64Encoded: encrypted.ciphertext) else {
            throw CryptoError.decryptionFailed
        }

        let sharedSecret = try await getSharedSecret(with: senderId)
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decrypted = try AES.GCM.open(sealedBox, using: sharedSecret)

        guard let text = String(data: decrypted, encoding: .utf8) else {
            throw CryptoError.decryptionFailed
        }
        return text
    }

    // MARK: - Shared Secret Derivation

    private func getSharedSecret(with userId: String) async throws -> SymmetricKey {
        if let cached = sharedSecrets[userId] {
            return cached
        }

        guard let privateKey else {
            throw CryptoError.noPrivateKey
        }

        // Fetch recipient's public key from Firestore
        let doc = try await db.collection("users").document(userId).getDocument()
        guard let publicKeyBase64 = doc.data()?["publicKey"] as? String,
              let publicKeyData = Data(base64Encoded: publicKeyBase64) else {
            throw CryptoError.noPublicKey
        }

        let publicKey = try P256.KeyAgreement.PublicKey(rawRepresentation: publicKeyData)
        let shared = try privateKey.sharedSecretFromKeyAgreement(with: publicKey)

        // Derive a symmetric key using HKDF
        let symmetricKey = shared.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data("status-app-e2e".utf8),
            sharedInfo: Data(),
            outputByteCount: 32
        )

        sharedSecrets[userId] = symmetricKey
        return symmetricKey
    }

    // MARK: - Keychain Storage

    private func savePrivateKey(_ key: P256.KeyAgreement.PrivateKey, userId: String) {
        let tag = "com.statusapp.e2e.\(userId)".data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "e2e-private-key-\(userId)",
            kSecAttrService as String: "com.statusapp.Status",
            kSecValueData as String: key.rawRepresentation
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadPrivateKey(userId: String) -> P256.KeyAgreement.PrivateKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "e2e-private-key-\(userId)",
            kSecAttrService as String: "com.statusapp.Status",
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return try? P256.KeyAgreement.PrivateKey(rawRepresentation: data)
    }

    // MARK: - Preview

    static var preview: CryptoService {
        CryptoService()
    }
}

struct EncryptedMessage {
    let ciphertext: String
    let isEncrypted: Bool
}

enum CryptoError: LocalizedError {
    case noPrivateKey
    case noPublicKey
    case encryptionFailed
    case decryptionFailed

    var errorDescription: String? {
        switch self {
        case .noPrivateKey: "Encryption keys not initialized."
        case .noPublicKey: "Recipient hasn't set up encryption yet."
        case .encryptionFailed: "Failed to encrypt message."
        case .decryptionFailed: "Failed to decrypt message."
        }
    }
}
