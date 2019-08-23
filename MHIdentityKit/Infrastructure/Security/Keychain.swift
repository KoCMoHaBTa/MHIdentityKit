//
//  Keychain.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 6/27/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation
import Security

class Keychain {
    
    let service: String
    
    public init(service: String) {
        
        self.service = service
    }
}

extension Keychain {
    
    func addGenericPassword(forUsername username: String, andPassword password: String) throws {
        
        var attributes = [String: Any]()
        attributes[kSecClass as String] = kSecClassGenericPassword
        attributes[kSecAttrAccount as String] = username
        attributes[kSecAttrGeneric as String] = password.data(using: .utf8)
        attributes[kSecAttrService as String] = self.service
        
        let status = SecItemAdd(attributes as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            
            throw OSStatusGetError(status)
        }
    }
    
    func allGenericPasswords() -> [(username: String, password: String)] {
        
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = self.service
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
        let items = result as? [[String: Any]] {
            
            var result = [(username: String, password: String)]()
            
            for item in items {
                
                if
                let username = item[kSecAttrAccount as String] as? String,
                let data = item[kSecAttrGeneric as String] as? Data,
                let password = String(data: data, encoding: .utf8) {
                    
                    result.append((username, password))
                }
            }
            
            return result
        }
        
        return []
    }
    
    func genericPassword(forUsername username: String) -> String? {
        
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = self.service
        query[kSecAttrAccount as String] = username
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
        let item = result as? NSDictionary,
        let data = item[kSecAttrGeneric as NSString] as? Data,
        let password = String(data: data, encoding: .utf8) else {
            
            return nil
        }
        
        return password
    }
    
    func removeGenericPassoword(forUsername username: String) throws {
        
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = self.service
        query[kSecAttrAccount as String] = username
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess else {
            
            throw OSStatusGetError(status)
        }
    }
    
    func removeAllGenericPasswords() throws {
        
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = self.service
        
        #if os(macOS)
            query[kSecMatchLimit as String] = kSecMatchLimitAll
        #endif
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess else {
            
            throw OSStatusGetError(status)
        }
    }
}
