import Foundation
import Security

/// Helpers for storing and retrieving sensitive values in the system Keychain.
enum KeychainService {
    /// Store a string value under the given key in the app's Keychain service.
    static func save(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else { return }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Constants.keychainServiceName,
            kSecAttrAccount: key
        ]
        let attributes: [CFString: Any] = [kSecValueData: data]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData] = data
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unhandledError(addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw KeychainError.unhandledError(updateStatus)
        }
    }

    /// Retrieve a string value for the given key from the Keychain.
    static func retrieve(forKey key: String) throws -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Constants.keychainServiceName,
            kSecAttrAccount: key,
            kSecReturnData: kCFBooleanTrue as Any,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status) }
        guard let data = result as? Data, let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.dataConversionError
        }
        return string
    }

    /// Remove the entry for the given key from the Keychain.
    static func delete(forKey key: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Constants.keychainServiceName,
            kSecAttrAccount: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status)
        }
    }
}

enum KeychainError: LocalizedError {
    case unhandledError(OSStatus)
    case dataConversionError

    var errorDescription: String? {
        switch self {
        case .unhandledError(let status): return "Keychain error (OSStatus \(status))."
        case .dataConversionError: return "Could not convert Keychain data to String."
        }
    }
}
