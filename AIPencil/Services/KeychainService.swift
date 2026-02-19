import Foundation
import Security

/// Manages secure storage of the Anthropic API key in the iOS Keychain.
///
/// Uses `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` so the key is:
/// - Encrypted at rest
/// - Only accessible when the device is unlocked
/// - Not included in backups or synced to other devices
final class KeychainService {
    static let shared = KeychainService()

    private let service = Constants.keychainServiceKey
    private let account = "anthropic-api-key"

    private init() {}

    // MARK: - Public API

    func saveAPIKey(_ key: String) throws {
        guard let data = key.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        // Delete any existing key first
        try? deleteAPIKey()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    func loadAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }

        return key
    }

    func deleteAPIKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    var hasAPIKey: Bool {
        loadAPIKey() != nil
    }

    /// Returns a masked version of the stored API key for display.
    /// Shows first 7 chars + "******" + last 4 chars (e.g. "sk-ant-******abcd").
    /// Returns nil if no key is stored.
    func maskedAPIKey() -> String? {
        guard let key = loadAPIKey() else { return nil }

        if key.count <= 11 {
            return String(repeating: "*", count: key.count)
        }

        let prefix = String(key.prefix(7))
        let suffix = String(key.suffix(4))
        return "\(prefix)******\(suffix)"
    }
}

// MARK: - Errors

enum KeychainError: LocalizedError {
    case encodingFailed
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode API key."
        case .saveFailed(let status):
            return "Keychain save failed (status: \(status))."
        case .deleteFailed(let status):
            return "Keychain delete failed (status: \(status))."
        }
    }
}
