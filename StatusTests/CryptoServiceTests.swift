import Foundation
import CryptoKit
import Testing
@testable import Status

@Suite("CryptoService")
struct CryptoServiceTests {

    @Test("EncryptedMessage with ephemeral key marks as encrypted")
    func encryptedMessageWithEphemeral() {
        let msg = EncryptedMessage(ciphertext: "abc", ephemeralPublicKey: "key123", isEncrypted: true)
        #expect(msg.isEncrypted)
        #expect(msg.ephemeralPublicKey == "key123")
    }

    @Test("EncryptedMessage without ephemeral key")
    func encryptedMessageWithoutEphemeral() {
        let msg = EncryptedMessage(ciphertext: "plain", isEncrypted: false)
        #expect(!msg.isEncrypted)
        #expect(msg.ephemeralPublicKey == nil)
    }

    @Test("CryptoError descriptions are set")
    func errorDescriptions() {
        #expect(CryptoError.noPrivateKey.errorDescription == "Encryption keys not initialized.")
        #expect(CryptoError.noPublicKey.errorDescription == "Recipient hasn't set up encryption yet.")
        #expect(CryptoError.encryptionFailed.errorDescription == "Failed to encrypt message.")
        #expect(CryptoError.decryptionFailed.errorDescription == "Failed to decrypt message.")
    }

    // MARK: - Raw CryptoKit verification (no Firestore)

    @Test("P256 key agreement produces valid shared secret")
    func keyAgreement() throws {
        let alice = P256.KeyAgreement.PrivateKey()
        let bob = P256.KeyAgreement.PrivateKey()

        let aliceShared = try alice.sharedSecretFromKeyAgreement(with: bob.publicKey)
        let bobShared = try bob.sharedSecretFromKeyAgreement(with: alice.publicKey)

        let aliceKey = aliceShared.hkdfDerivedSymmetricKey(using: SHA256.self, salt: Data("test".utf8), sharedInfo: Data(), outputByteCount: 32)
        let bobKey = bobShared.hkdfDerivedSymmetricKey(using: SHA256.self, salt: Data("test".utf8), sharedInfo: Data(), outputByteCount: 32)

        // Both sides derive the same key
        let plaintext = Data("hello world".utf8)
        let sealed = try AES.GCM.seal(plaintext, using: aliceKey)
        let opened = try AES.GCM.open(sealed, using: bobKey)
        #expect(opened == plaintext)
    }

    @Test("Ephemeral key provides forward secrecy")
    func ephemeralForwardSecrecy() throws {
        let recipient = P256.KeyAgreement.PrivateKey()

        // Message 1: ephemeral key 1
        let ephemeral1 = P256.KeyAgreement.PrivateKey()
        let shared1 = try ephemeral1.sharedSecretFromKeyAgreement(with: recipient.publicKey)
        let key1 = shared1.hkdfDerivedSymmetricKey(using: SHA256.self, salt: Data("status-e2e-ephemeral".utf8), sharedInfo: Data(), outputByteCount: 32)

        // Message 2: ephemeral key 2
        let ephemeral2 = P256.KeyAgreement.PrivateKey()
        let shared2 = try ephemeral2.sharedSecretFromKeyAgreement(with: recipient.publicKey)
        let key2 = shared2.hkdfDerivedSymmetricKey(using: SHA256.self, salt: Data("status-e2e-ephemeral".utf8), sharedInfo: Data(), outputByteCount: 32)

        // Keys should be different (different ephemeral keys)
        let data1 = key1.withUnsafeBytes { Data($0) }
        let data2 = key2.withUnsafeBytes { Data($0) }
        #expect(data1 != data2)

        // Recipient can decrypt both using their identity key + each ephemeral public key
        let plaintext = Data("secret".utf8)
        let sealed1 = try AES.GCM.seal(plaintext, using: key1)
        let sealed2 = try AES.GCM.seal(plaintext, using: key2)

        // Derive decryption keys from recipient side
        let decryptKey1 = try recipient.sharedSecretFromKeyAgreement(with: ephemeral1.publicKey)
            .hkdfDerivedSymmetricKey(using: SHA256.self, salt: Data("status-e2e-ephemeral".utf8), sharedInfo: Data(), outputByteCount: 32)
        let decryptKey2 = try recipient.sharedSecretFromKeyAgreement(with: ephemeral2.publicKey)
            .hkdfDerivedSymmetricKey(using: SHA256.self, salt: Data("status-e2e-ephemeral".utf8), sharedInfo: Data(), outputByteCount: 32)

        let opened1 = try AES.GCM.open(sealed1, using: decryptKey1)
        let opened2 = try AES.GCM.open(sealed2, using: decryptKey2)
        #expect(opened1 == plaintext)
        #expect(opened2 == plaintext)

        // Key 1 cannot decrypt message 2 (forward secrecy)
        #expect(throws: (any Error).self) {
            _ = try AES.GCM.open(sealed2, using: decryptKey1)
        }
    }

    @Test("Message model tracks encryption state")
    func messageEncryptionState() {
        let encrypted = Message(id: "1", conversationId: "c", senderId: "a", text: "cipher", ephemeralPublicKey: "key", sentAt: .now)
        let plain = Message(id: "2", conversationId: "c", senderId: "a", text: "hello", sentAt: .now)

        #expect(encrypted.isEncrypted)
        #expect(!plain.isEncrypted)
    }
}
