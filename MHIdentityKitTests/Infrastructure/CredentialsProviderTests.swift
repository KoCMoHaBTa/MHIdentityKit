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
    
    func testDefaultCredentialsProvider() async throws {
        
        let provider: CredentialsProvider = AnyCredentialsProvider(username: "tuname", password: "tpsswd")
        let (username, password) = await provider.credentials()
        
        XCTAssertEqual(username, "tuname")
        XCTAssertEqual(password, "tpsswd")
    }
}
