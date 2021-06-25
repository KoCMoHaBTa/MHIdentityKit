//
//  InMemoryIdentityStorage.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/26/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///A default in-memory storage
public class InMemoryIdentityStorage: IdentityStorage {
    
    private var storage: [String: String] = [:]
    
    public init() {}
    
    public func set(_ value: String?, forKey key: String) {
        
        storage[key] = value
    }
    
    public func value(forKey key: String) -> String? {
        
        return storage[key]
    }
}

extension IdentityStorage where Self == InMemoryIdentityStorage {
    
    public static var inMemory: Self { .init() }
}
