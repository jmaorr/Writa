//
//  KeychainService.swift
//  Writa
//
//  Secure storage for sensitive data like auth tokens.
//  Uses the iOS/macOS Keychain for encryption at rest.
//

import Foundation
import Security

// MARK: - Keychain Service

final class KeychainService {
    
    /// Shared singleton instance
    static let shared = KeychainService()
    
    /// Service identifier for keychain items
    private let service = "com.writa.app"
    
    /// Access group for shared keychain (if needed for extensions)
    private let accessGroup: String? = nil
    
    private init() {}
    
    // MARK: - Save
    
    /// Save a string value to the keychain
    @discardableResult
    func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }
        return save(data, forKey: key)
    }
    
    /// Save data to the keychain
    @discardableResult
    func save(_ data: Data, forKey key: String) -> Bool {
        // Delete any existing item first
        delete(forKey: key)
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("❌ Keychain save error: \(status)")
        }
        
        return status == errSecSuccess
    }
    
    // MARK: - Read
    
    /// Read a string value from the keychain
    func getString(forKey key: String) -> String? {
        guard let data = getData(forKey: key) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    /// Read data from the keychain
    func getData(forKey key: String) -> Data? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        }
        
        return nil
    }
    
    // MARK: - Delete
    
    /// Delete a value from the keychain
    @discardableResult
    func delete(forKey key: String) -> Bool {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemDelete(query as CFDictionary)
        
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// Delete all keychain items for this service
    @discardableResult
    func deleteAll() -> Bool {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemDelete(query as CFDictionary)
        
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Update
    
    /// Update an existing keychain item
    @discardableResult
    func update(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }
        return update(data, forKey: key)
    }
    
    /// Update an existing keychain item with data
    @discardableResult
    func update(_ data: Data, forKey key: String) -> Bool {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        // If item doesn't exist, create it
        if status == errSecItemNotFound {
            return save(data, forKey: key)
        }
        
        return status == errSecSuccess
    }
    
    // MARK: - Existence Check
    
    /// Check if a key exists in the keychain
    func exists(forKey key: String) -> Bool {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        
        return status == errSecSuccess
    }
}

// MARK: - Common Keys

extension KeychainService {
    /// Key for storing the auth token
    static let authTokenKey = "auth_token"
    
    /// Key for storing the refresh token
    static let refreshTokenKey = "refresh_token"
    
    /// Key for storing the user ID
    static let userIdKey = "user_id"
}

// MARK: - Codable Support

extension KeychainService {
    /// Save a Codable object to the keychain
    @discardableResult
    func save<T: Encodable>(_ object: T, forKey key: String) -> Bool {
        do {
            let data = try JSONEncoder().encode(object)
            return save(data, forKey: key)
        } catch {
            print("❌ Keychain encode error: \(error)")
            return false
        }
    }
    
    /// Read a Codable object from the keychain
    func get<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = getData(forKey: key) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("❌ Keychain decode error: \(error)")
            return nil
        }
    }
}
