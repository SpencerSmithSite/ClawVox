import Foundation
import Security

/// Helpers for storing and retrieving sensitive values in the system Keychain.
enum KeychainService {
    /// Store a string value under the given key in the app's Keychain service.
    static func save(_ value: String, forKey key: String) throws {
        // TODO: Build SecItemAdd / SecItemUpdate query and write value
    }

    /// Retrieve a string value for the given key from the Keychain.
    static func retrieve(forKey key: String) throws -> String? {
        // TODO: Build SecItemCopyMatching query and decode result
        return nil
    }

    /// Remove the entry for the given key from the Keychain.
    static func delete(forKey key: String) throws {
        // TODO: Build SecItemDelete query
    }
}
