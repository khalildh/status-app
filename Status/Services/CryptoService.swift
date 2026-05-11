import Foundation
import CryptoKit
@preconcurrency import FirebaseFirestore

@MainActor
@Observable
final class CryptoService {
    @ObservationIgnored private var _db: Firestore?
    private var db: Firestore { if _db == nil { _db = Firestore.firestore() }; return _db! }

    // Long-term identity key pair stored in Keychain
    @ObservationIgnored private var identityKey: P256.KeyAgreement.PrivateKey?

    // Cache of recipient public keys
    @ObservationIgnored private var publicKeyCache: [String: P256.KeyAgreement.PublicKey] = [:]

    // MARK: - Key Management

    /// Generate or load the user's identity key pair. Called once at login.
    func initialize(userId: String) async throws {
        if let existingKey = loadPrivateKey(userId: userId) {
            identityKey = existingKey
        } else {
            let newKey = P256.KeyAgreement.PrivateKey()
            identityKey = newKey
            savePrivateKey(newKey, userId: userId)
        }

        // Publish public key to Firestore
        guard let identityKey else { return }
        let publicKeyData = identityKey.publicKey.rawRepresentation.base64EncodedString()
        try await db.collection("users").document(userId).updateData([
            "publicKey": publicKeyData
        ])
    }

    // MARK: - Encrypt (with ephemeral key for forward secrecy)

    /// Each message gets a fresh ephemeral key pair.
    /// The ephemeral public key is sent alongside the ciphertext.
    /// Even if the identity key is compromised, past messages stay safe.
    func encrypt(_ plaintext: String, for recipientId: String) async throws -> EncryptedMessage {
        let recipientPublicKey = try await getPublicKey(for: recipientId)

        // Generate a fresh ephemeral key pair for THIS message only
        let ephemeralKey = P256.KeyAgreement.PrivateKey()
        let ephemeralPublicKeyData = ephemeralKey.publicKey.rawRepresentation.base64EncodedString()

        // Derive shared secret from ephemeral private + recipient's public
        let shared = try ephemeralKey.sharedSecretFromKeyAgreement(with: recipientPublicKey)
        let symmetricKey = shared.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data("status-e2e-ephemeral".utf8),
            sharedInfo: Data(),
            outputByteCount: 32
        )

        // Encrypt the message
        let data = Data(plaintext.utf8)
        let sealed = try AES.GCM.seal(data, using: symmetricKey)
        guard let combined = sealed.combined else {
            throw CryptoError.encryptionFailed
        }

        // Ephemeral private key is never stored — discarded after this function returns
        return EncryptedMessage(
            ciphertext: combined.base64EncodedString(),
            ephemeralPublicKey: ephemeralPublicKeyData,
            isEncrypted: true
        )
    }

    // MARK: - Decrypt (using our identity key + sender's ephemeral key)

    func decrypt(_ encrypted: EncryptedMessage, from senderId: String) async throws -> String {
        guard encrypted.isEncrypted else {
            return encrypted.ciphertext
        }

        guard let identityKey else {
            throw CryptoError.noPrivateKey
        }

        // If there's an ephemeral key, use it (new protocol)
        // Otherwise fall back to static key agreement (old messages)
        let symmetricKey: SymmetricKey

        if let ephemeralBase64 = encrypted.ephemeralPublicKey,
           let ephemeralData = Data(base64Encoded: ephemeralBase64) {
            // New protocol: sender's ephemeral public key + our identity private key
            let ephemeralPublicKey = try P256.KeyAgreement.PublicKey(rawRepresentation: ephemeralData)
            let shared = try identityKey.sharedSecretFromKeyAgreement(with: ephemeralPublicKey)
            symmetricKey = shared.hkdfDerivedSymmetricKey(
                using: SHA256.self,
                salt: Data("status-e2e-ephemeral".utf8),
                sharedInfo: Data(),
                outputByteCount: 32
            )
        } else {
            // Legacy: static ECDH with sender's identity key
            let senderPublicKey = try await getPublicKey(for: senderId)
            let shared = try identityKey.sharedSecretFromKeyAgreement(with: senderPublicKey)
            symmetricKey = shared.hkdfDerivedSymmetricKey(
                using: SHA256.self,
                salt: Data("status-app-e2e".utf8),
                sharedInfo: Data(),
                outputByteCount: 32
            )
        }

        guard let data = Data(base64Encoded: encrypted.ciphertext) else {
            throw CryptoError.decryptionFailed
        }
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decrypted = try AES.GCM.open(sealedBox, using: symmetricKey)

        guard let text = String(data: decrypted, encoding: .utf8) else {
            throw CryptoError.decryptionFailed
        }
        return text
    }

    // MARK: - Public Key Fetching

    private func getPublicKey(for userId: String) async throws -> P256.KeyAgreement.PublicKey {
        if let cached = publicKeyCache[userId] {
            return cached
        }

        let doc = try await db.collection("users").document(userId).getDocument()
        guard let publicKeyBase64 = doc.data()?["publicKey"] as? String,
              let publicKeyData = Data(base64Encoded: publicKeyBase64) else {
            throw CryptoError.noPublicKey
        }

        let publicKey = try P256.KeyAgreement.PublicKey(rawRepresentation: publicKeyData)
        publicKeyCache[userId] = publicKey
        return publicKey
    }

    // MARK: - Keychain Storage

    private func savePrivateKey(_ key: P256.KeyAgreement.PrivateKey, userId: String) {
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
    let ephemeralPublicKey: String?
    let isEncrypted: Bool

    init(ciphertext: String, ephemeralPublicKey: String? = nil, isEncrypted: Bool) {
        self.ciphertext = ciphertext
        self.ephemeralPublicKey = ephemeralPublicKey
        self.isEncrypted = isEncrypted
    }
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
