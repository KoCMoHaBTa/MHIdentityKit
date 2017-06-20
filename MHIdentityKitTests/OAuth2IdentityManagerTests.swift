//
//  OAuth2IdentityManagerTests.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 6/5/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

import XCTest
@testable import MHIdentityKit

class OAuth2IdentityManagerTests: XCTestCase {
    
    func testOAuth2IdentityManager() {
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 10
            
            class Flow: AuthorizationGrantFlow {
                
                let e: XCTestExpectation
                private var callCount = 0
                
                init(e: XCTestExpectation) {
                    
                    self.e = e
                }
                
                func authenticate(handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
                    
                    e.fulfill()
                    callCount += 1
                    
                    if callCount == 1 {
                        
                        //simulate expired token
                        handler(AccessTokenResponse(accessToken: "tat1", tokenType: "Bearer", expiresIn: 0, refreshToken: "trt1", scope: nil), nil)
                    }
                    else if callCount == 2 {
                        
                        //simulate valid token
                        handler(AccessTokenResponse(accessToken: "tat2", tokenType: "Bearer", expiresIn: 1234, refreshToken: "trt2", scope: nil), nil)
                    }
                    else {
                        
                        handler(nil, "simulate error")
                    }
                }
            }
            
            class Refresher: AccessTokenRefresher {
                
                let e: XCTestExpectation
                private var callCount = 0
                
                init(e: XCTestExpectation) {
                    
                    self.e = e
                }
                
                func refresh(using requestModel: AccessTokenRefreshRequest, handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
                    
                    e.fulfill()
                    callCount += 1
                    
                    if callCount == 1 {
                        
                        XCTAssertEqual(requestModel.refreshToken, "trt1")
                        handler(AccessTokenResponse(accessToken: "rtat", tokenType: "Bearer", expiresIn: 0, refreshToken: "trt3", scope: nil), nil)
                    }
                    else {
                        
                        XCTAssertEqual(requestModel.refreshToken, "trt3")
                        handler(nil, "simulate error")
                    }
                }
            }
            
            let manager = OAuth2IdentityManager(flow: Flow(e: e), refresher: Refresher(e: e), storage: InMemoryIdentityStorage(), authorizationMethod: .header)
            
            manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!), forceAuthenticate: false, handler: { (request, error) in
                
                XCTAssertNil(error)
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer tat1")
                e.fulfill()
            })
            
            manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!), forceAuthenticate: false, handler: { (request, error) in
                
                XCTAssertNil(error)
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer rtat")
                e.fulfill()
            })
            
            manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!), forceAuthenticate: false, handler: { (request, error) in
                
                XCTAssertNil(error)
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer tat2")
                e.fulfill()
            })
            
            manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!), forceAuthenticate: false, handler: { (request, error) in
                
                XCTAssertNil(error)
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer tat2")
                e.fulfill()
            })
            
            manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!), forceAuthenticate: true, handler: { (request, error) in
                
                XCTAssertNotNil(error)
                XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
                e.fulfill()
            })
        }
    }
    
    func testForceAuthenticateOnRefreshError() {
        
        class Flow: AuthorizationGrantFlow {
            
            func authenticate(handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
                
                handler(AccessTokenResponse(accessToken: "tat1", tokenType: "Bearer", expiresIn: 0, refreshToken: "trt1", scope: nil), nil)
            }
        }
        
        class Refresher: AccessTokenRefresher {
            
            func refresh(using requestModel: AccessTokenRefreshRequest, handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
                
                handler(nil, "refresh error")
            }
        }
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 2
            
            let manager = OAuth2IdentityManager(flow: Flow(), refresher: Refresher(), storage: InMemoryIdentityStorage(), authorizationMethod: .header)
            manager.forceAuthenticateOnRefreshError = true
            manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!), handler: { (request, error) in
                
                XCTAssertNil(error)
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer tat1")
                e.fulfill()
            })
            
            manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!), handler: { (request, error) in
                
                XCTAssertNil(error)
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer tat1")
                e.fulfill()
            })
        }
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 2
            
            let manager = OAuth2IdentityManager(flow: Flow(), refresher: Refresher(), storage: InMemoryIdentityStorage(), authorizationMethod: .header)
            manager.forceAuthenticateOnRefreshError = false
            manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!), handler: { (request, error) in
                
                XCTAssertNil(error)
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer tat1")
                e.fulfill()
            })
            
            manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!), handler: { (request, error) in
                
                XCTAssertNotNil(error)
                XCTAssertEqual(error as? String, "refresh error")
                XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
                e.fulfill()
            })
        }
    }
    
    func testSynchronousAuthorization() {
        
        class Flow: AuthorizationGrantFlow {
            
            func authenticate(handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
                
                handler(AccessTokenResponse(accessToken: "tat1", tokenType: "Bearer", expiresIn: 0, refreshToken: "trt1", scope: nil), nil)
            }
        }
        
        let manager = OAuth2IdentityManager(flow: Flow(), refresher: nil, storage: InMemoryIdentityStorage(), authorizationMethod: .header)        
        
        let request = try! URLRequest(url: URL(string: "http://foo.bar")!).authorized(using: manager)
        
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer tat1")
    }
}
