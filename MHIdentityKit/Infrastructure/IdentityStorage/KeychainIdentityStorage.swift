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
        
        try? keychain.removeGenericPassoword(forUsername: key)
        value.map { try? keychain.addGenericPassword(forUsername: key, andPassword: $0) }
    }
    
    public func value(forKey key: String) -> String? {
        
        keychain.genericPassword(forUsername: key)
    }
}

extension IdentityStorage where Self == KeychainIdentityStorage {
    
    public static func keychain(service: String) -> Self {
        
        .init(service: service)
    }
}
