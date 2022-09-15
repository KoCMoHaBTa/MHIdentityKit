//
//  CredentialsProviderTests.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 6/2/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import MHIdentityKit

class CredentialsProviderTests: XCTestCase {
    
    func testDefaultCredentialsProvider() {
        
        let provider: CredentialsProvider = AnyCredentialsProvider(username: "tuname", password: "tpsswd")
        
        self.performExpectation { (e) in
            
            provider.credentials { (username, password) in
             
                XCTAssertEqual(username, "tuname")
                XCTAssertEqual(password, "tpsswd")
                e.fulfill()
            }
        }
    }
    
    @available(iOS 13, tvOS 13.0.0, macOS 10.15, *)
    func testDefaultCredentialsProvider() async {
        
        let provider: CredentialsProvider = AnyCredentialsProvider(username: "tuname", password: "tpsswd")
        
        let credentials = await provider.credentials()
        let username = credentials.0
        let password = credentials.1
             
        XCTAssertEqual(username, "tuname")
        XCTAssertEqual(password, "tpsswd")
    }
}
