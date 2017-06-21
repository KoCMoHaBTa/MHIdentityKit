//
//  IdentityStorage.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/23/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///A type that stores identity information. It is preferable that this implementation stores the data into a secure place, like the keychain
public protocol IdentityStorage: class {
    
    ///Stores or updates a value for a given key. If value is nil - previously stored value is removed.
    func set(_ value: String?, forKey key: String)
    
    ///Retrieves a value for a given key.
    func value(forKey key: String) -> String?
}

extension IdentityStorage {
    
    //implements a subscript behaviour
    public subscript(key: String) -> String? {
        
        get {
            
            return self.value(forKey: key)
        }
        
        set {
            
            self.set(newValue, forKey: key)
        }
    }
}

