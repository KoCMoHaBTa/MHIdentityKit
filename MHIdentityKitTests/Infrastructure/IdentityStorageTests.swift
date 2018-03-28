//
//  IdentityStorageTests.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 6/2/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import MHIdentityKit

class IdentityStorageTests: XCTestCase {
    
    func testInMemoryIdentityStorage() {
        
        let storage: IdentityStorage = InMemoryIdentityStorage()
        
        storage.set(nil, forKey: "gg5")
        XCTAssertNil(storage.value(forKey: "gg5"))
        
        storage.set("tv", forKey: "tk")
        XCTAssertEqual(storage.value(forKey: "tk"), "tv")
        XCTAssertNil(storage.value(forKey: "tk2"))
        
        storage.set("tv5", forKey: "tk")
        XCTAssertEqual(storage.value(forKey: "tk"), "tv5")
        
        storage.set(nil, forKey: "tk")
        XCTAssertNil(storage.value(forKey: "tk"))
    }
    
    func testKeychainIdentityStorage() {
        
        let storage: IdentityStorage = KeychainIdentityStorage(service: "test")
        
        storage.set(nil, forKey: "gg5")
        XCTAssertNil(storage.value(forKey: "gg5"))
        
        storage.set("tv", forKey: "tk")
        XCTAssertEqual(storage.value(forKey: "tk"), "tv")
        XCTAssertNil(storage.value(forKey: "tk2"))
        
        storage.set("tv5", forKey: "tk")
        XCTAssertEqual(storage.value(forKey: "tk"), "tv5")
        
        storage.set(nil, forKey: "tk")
        XCTAssertNil(storage.value(forKey: "tk"))
    }
}
