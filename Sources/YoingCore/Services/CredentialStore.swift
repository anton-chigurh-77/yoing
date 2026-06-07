import Foundation
import Security

public protocol CredentialStoring {
    func saveXAIAPIKey(_ key: String) throws
    func readXAIAPIKey() throws -> String?
    func deleteXAIAPIKey() throws
}

public enum CredentialStoreError: LocalizedError {
    case emptyKey
    case unexpectedData
    case keychainStatus(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .emptyKey:
            return "Enter an xAI API key before saving."
        case .unexpectedData:
            return "The saved xAI API key could not be read."
        case .keychainStatus(let status):
            return "Keychain returned status \(status)."
        }
    }
}

public final class KeychainCredentialStore: CredentialStoring {
    private let service = "com.yoing.app"
    private let account = "xai.api-key"

    public init() {}

    public func saveXAIAPIKey(_ key: String) throws {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CredentialStoreError.emptyKey
        }

        let data = Data(trimmed.utf8)
        let query = baseQuery()

        let update: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw CredentialStoreError.keychainStatus(updateStatus)
        }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw CredentialStoreError.keychainStatus(addStatus)
        }
    }

    public func readXAIAPIKey() throws -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw CredentialStoreError.keychainStatus(status)
        }

        guard let data = item as? Data, let value = String(data: data, encoding: .utf8) else {
            throw CredentialStoreError.unexpectedData
        }

        return value
    }

    public func deleteXAIAPIKey() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CredentialStoreError.keychainStatus(status)
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
