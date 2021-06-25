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
extension String: LocalizedError {
    
    public var errorDescription: String? { self }
}

class MHIdentityKitTests: XCTestCase {
    
    func testScope() {
        
        XCTAssertEqual(Scope(rawValue: "read write").components, ["read", "write"])
        XCTAssertEqual(Scope(components: ["read", "write"]).rawValue, "read write")
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

func XCTAwait<T>(_ value: @autoclosure () async -> T, assert: (_ value: T) -> Void) async {
    
    let value = await value()
    assert(value)
}
