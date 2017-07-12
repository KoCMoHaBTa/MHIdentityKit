//
//  MHIdentityKitTests.swift
//  MHIdentityKitTests
//
//  Created by Milen Halachev on 4/11/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import XCTest
@testable import MHIdentityKit

extension String: Error {}

class TestNetworkClient: NetworkClient {
    
    let handler: (URLRequest, (NetworkResponse) -> Void) -> Void
    
    init(handler: @escaping (URLRequest, (NetworkResponse) -> Void) -> Void) {
        
        self.handler = handler
    }
    
    func perform(_ request: URLRequest, completion: @escaping (NetworkResponse) -> Void) {
        
        self.handler(request, completion)
    }
}

class MHIdentityKitTests: XCTestCase {
    
    func testScope() {
        
        XCTAssertEqual(Scope(value: "read write").components, ["read", "write"])
        XCTAssertEqual(Scope(components: ["read", "write"]).value, "read write")
    }
    
    func testKeychain() {
                
        let keychain = Keychain(service: "test")
        XCTAssertNil(keychain.genericPassword(forUsername: "gg"))
        XCTAssertNil(keychain.genericPassword(forUsername: "gg2"))
        XCTAssertNil(keychain.genericPassword(forUsername: "gg3"))
        
        try? keychain.addGenericPassword(forUsername: "gg", andPassword: "zz")
        try? keychain.addGenericPassword(forUsername: "gg2", andPassword: "zz2")
        try? keychain.addGenericPassword(forUsername: "gg3", andPassword: "zz3")
        XCTAssertEqual(keychain.genericPassword(forUsername: "gg"), "zz")
        XCTAssertEqual(keychain.genericPassword(forUsername: "gg2"), "zz2")
        XCTAssertEqual(keychain.genericPassword(forUsername: "gg3"), "zz3")
        
        try? keychain.removeGenericPassoword(forUsername: "gg")
        XCTAssertNil(keychain.genericPassword(forUsername: "gg"))
        XCTAssertEqual(keychain.genericPassword(forUsername: "gg2"), "zz2")
        XCTAssertEqual(keychain.genericPassword(forUsername: "gg3"), "zz3")
        
        try? keychain.removeAllGenericPasswords()
        XCTAssertNil(keychain.genericPassword(forUsername: "gg"))
        XCTAssertNil(keychain.genericPassword(forUsername: "gg2"))
        XCTAssertNil(keychain.genericPassword(forUsername: "gg3"))
    }
}
