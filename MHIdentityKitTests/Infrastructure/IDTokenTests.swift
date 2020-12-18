//
//  IDTokenTests.swift
//  MHIdentityKit-iOSTests
//
//  Created by Milen Halachev on 18.12.20.
//  Copyright © 2020 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import MHIdentityKit

class IDTokenTests: XCTestCase {
    
    func testAudience() throws {
        
        //allows only creation with String or [String]
        XCTAssertNil(IDToken.Audience(nil))
        XCTAssertNil(IDToken.Audience(5))
        XCTAssertNil(IDToken.Audience([1, 5]))
        XCTAssertNotNil(IDToken.Audience("asd"))
        XCTAssertNotNil(IDToken.Audience(["test", "asd"]))
        
        //test clientID contains
        try XCTAssertTrue(XCTUnwrap(IDToken.Audience("asd")).contains(clientID: "asd"))
        try XCTAssertFalse(XCTUnwrap(IDToken.Audience("asd")).contains(clientID: "zzz"))
        try XCTAssertTrue(XCTUnwrap(IDToken.Audience(["omg", "asd", "wtf"])).contains(clientID: "asd"))
        try XCTAssertFalse(XCTUnwrap(IDToken.Audience(["omg", "asd", "wtf"])).contains(clientID: "zzz"))
        
        //test trusted validation
        try XCTAssertTrue(XCTUnwrap(IDToken.Audience("asd")).validate(trusted: nil))
        try XCTAssertTrue(XCTUnwrap(IDToken.Audience("asd")).validate(trusted: "asd"))
        try XCTAssertTrue(XCTUnwrap(IDToken.Audience("asd")).validate(trusted: ["asd"]))
        try XCTAssertFalse(XCTUnwrap(IDToken.Audience("asd")).validate(trusted: "omg"))
        try XCTAssertFalse(XCTUnwrap(IDToken.Audience("asd")).validate(trusted: ["omg"]))
        try XCTAssertTrue(XCTUnwrap(IDToken.Audience("asd")).validate(trusted: ["asd", "omg"]))
        
        try XCTAssertTrue(XCTUnwrap(IDToken.Audience(["omg", "asd", "wtf"])).validate(trusted: nil))
        
        //shold not contain more than  trusted
        try XCTAssertFalse(XCTUnwrap(IDToken.Audience(["omg", "asd", "wtf"])).validate(trusted: "asd"))
        try XCTAssertFalse(XCTUnwrap(IDToken.Audience(["omg", "asd", "wtf"])).validate(trusted: ["asd"]))
        
        //order should not matter
        try XCTAssertTrue(XCTUnwrap(IDToken.Audience(["omg", "asd", "wtf"])).validate(trusted: ["asd", "omg", "wtf"]))
        try XCTAssertTrue(XCTUnwrap(IDToken.Audience(["omg", "asd", "wtf"])).validate(trusted: ["asd", "omg", "wtf", "zzz"]))
    }
}
