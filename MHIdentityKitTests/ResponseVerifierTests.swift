//
//  ResponseVerifierTests.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/26/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import MHIdentityKit

class ResponseVerifierTests: XCTestCase {
    
    func testVerifier() {
        
        let verifier = AnyResponseVerifier { (data, response, error) in
            
            guard data != nil else { throw "nil data" }
            guard response != nil else { throw "nil response" }
            guard error == nil else { throw error! }
        }
        
        //success
        self.performExpectation { (e) in
            
            do {
                
                try verifier.verify(data: Data(), response: URLResponse(), error: nil)
            }
            catch {
                
                XCTFail()
                return
            }
            
            e.fulfill()
        }
        
        //nil data
        self.performExpectation { (e) in
            
            do {
                
                try verifier.verify(data: nil, response: URLResponse(), error: nil)
            }
            catch {
                
                XCTAssertEqual(error as! String, "nil data")
                e.fulfill()
                return
            }
            
            XCTFail()
        }
        
        //nil response
        self.performExpectation { (e) in
            
            do {
                
                try verifier.verify(data: Data(), response: nil, error: nil)
            }
            catch {
                
                XCTAssertEqual(error as! String, "nil response")
                e.fulfill()
                return
            }
            
            XCTFail()
        }
        
        //error present
        self.performExpectation { (e) in
            
            do {
                
                try verifier.verify(data: Data(), response: URLResponse(), error: "test error")
            }
            catch {
                
                XCTAssertEqual(error as! String, "test error")
                e.fulfill()
                return
            }
            
            XCTFail()
        }
    }
    
    func testVerifierComposition() {
        
        let v1_fail = AnyResponseVerifier(handler: { _,_,_ in throw "v1" })
        let v2_fail = AnyResponseVerifier(handler: { _,_,_ in throw "v2" })
        let v3_success = AnyResponseVerifier(handler: { _,_,_ in })
        
        //v1 + v2 throws v1
        self.performExpectation { (e) in
            
            do {
                
                try [v1_fail, v2_fail].verify(data: nil, response: nil, error: nil)
            }
            catch {
                
                XCTAssertEqual(error as! String, "v1")
                e.fulfill()
                return
            }
            
            XCTFail()
        }
        
        //v2 + v1 throws v2
        self.performExpectation { (e) in
            
            do {
                
                try [v2_fail, v1_fail].verify(data: nil, response: nil, error: nil)
            }
            catch {
                
                XCTAssertEqual(error as! String, "v2")
                e.fulfill()
                return
            }
            
            XCTFail()
        }
        
        //v2 + v3 throws v2
        self.performExpectation { (e) in
            
            do {
                
                try [v2_fail, v3_success].verify(data: nil, response: nil, error: nil)
            }
            catch {
                
                XCTAssertEqual(error as! String, "v2")
                e.fulfill()
                return
            }
            
            XCTFail()
        }
        
        //v3 + v2 throws v2
        self.performExpectation { (e) in
            
            do {
                
                try [v3_success, v2_fail].verify(data: nil, response: nil, error: nil)
            }
            catch {
                
                XCTAssertEqual(error as! String, "v2")
                e.fulfill()
                return
            }
            
            XCTFail()
        }
        
        //v3 + v3 - ok
        self.performExpectation { (e) in
            
            do {
                
                try [v3_success, v3_success].verify(data: nil, response: nil, error: nil)
            }
            catch {
                
                XCTFail()
                return
            }
            
            e.fulfill()
        }
    }
}


