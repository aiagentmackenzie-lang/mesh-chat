import Foundation
import CryptoKit

nonisolated struct KeyPair: Sendable {
    let publicKey: String
    let privateKey: String
}

nonisolated enum CryptoService: Sendable {
    static func generateKeyPair() -> KeyPair {
        let privateKey = P256.KeyAgreement.PrivateKey()
        let publicKeyData = privateKey.publicKey.compactRepresentation ?? Data()
        let privateKeyData = privateKey.rawRepresentation
        return KeyPair(
            publicKey: publicKeyData.base64EncodedString(),
            privateKey: privateKeyData.base64EncodedString()
        )
    }

    static func generateSymmetricKey() -> String {
        let key = SymmetricKey(size: .bits256)
        return key.withUnsafeBytes { Data($0).base64EncodedString() }
    }

    static func encrypt(_ plaintext: String, key: String) -> String? {
        guard let keyData = Data(base64Encoded: key),
              let plaintextData = plaintext.data(using: .utf8) else { return nil }
        let symmetricKey = SymmetricKey(data: keyData)
        guard let sealedBox = try? AES.GCM.seal(plaintextData, using: symmetricKey) else { return nil }
        return sealedBox.combined?.base64EncodedString()
    }

    static func decrypt(_ ciphertext: String, key: String) -> String? {
        guard let keyData = Data(base64Encoded: key),
              let ciphertextData = Data(base64Encoded: ciphertext) else { return nil }
        let symmetricKey = SymmetricKey(data: keyData)
        guard let sealedBox = try? AES.GCM.SealedBox(combined: ciphertextData),
              let decryptedData = try? AES.GCM.open(sealedBox, using: symmetricKey) else { return nil }
        return String(data: decryptedData, encoding: .utf8)
    }

    static func generatePairingCode() -> String {
        String(format: "%04d", Int.random(in: 1000...9999))
    }
}
