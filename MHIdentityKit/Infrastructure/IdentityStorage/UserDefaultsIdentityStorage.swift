//
//  UserDefaultsIdentityStorage.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 6/19/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///An identity storage that wraps UserDefaults
public class UserDefaultsIdentityStorage: IdentityStorage {
    
    public let userDefaults: UserDefaults
    
    public init(_ userDefaults: UserDefaults) {
        
        self.userDefaults = userDefaults
    }
    
    public func set(_ value: String?, forKey key: String) {
        
        userDefaults.set(value, forKey: key)
        userDefaults.synchronize()
    }
    
    public func value(forKey key: String) -> String? {
     
        return userDefaults.value(forKey: key) as? String
    }
}

extension IdentityStorage where Self == UserDefaultsIdentityStorage {
    
    public static func userDefaults(_ userDefaults: UserDefaults) -> Self {
        
        .init(userDefaults)
    }
}
