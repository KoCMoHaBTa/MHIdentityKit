//
//  KeychainIdentityStorage.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 6/27/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation
import Security

///A keychain based storage
public class KeychainIdentityStorage: IdentityStorage {
    
    private let keychain: Keychain
    
    public init(service: String) {
        
        self.keychain = Keychain(service: service)
    }
    
    public func set(_ value: String?, forKey key: String) {
        
        try? self.keychain.removeGenericPassoword(forUsername: key)
        
        if let value = value {
            
            try? self.keychain.addGenericPassword(forUsername: key, andPassword: value)
        }
    }
    
    public func value(forKey key: String) -> String? {
        
        return self.keychain.genericPassword(forUsername: key)
    }
}
