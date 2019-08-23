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
                        
                        handler(nil, ErrorResponse(code: .invalidGrant))
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
                        handler(nil, MHIdentityKitError.authenticationFailed(reason: MHIdentityKitError(error: ErrorResponse(code: .invalidGrant))))
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
                
                handler(nil, MHIdentityKitError.authenticationFailed(reason: MHIdentityKitError(error: ErrorResponse(code: .invalidGrant))))
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
    
    func testSerialAuthorizationBehaviour() {
        
        //if multiple authorization calls are made - only 1 should perform authentication :):)
        
        class Flow: AuthorizationGrantFlow {
            
            let e: XCTestExpectation
            private var callCount = 0
            
            init(e: XCTestExpectation) {
                
                self.e = e
            }
            
            func authenticate(handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
                
                e.fulfill()
                callCount += 1
                
                guard callCount == 1 else {
                    
                    XCTFail()
                    return
                }
                
                DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + (2 * Double(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
                    
                    handler(AccessTokenResponse(accessToken: "tat1", tokenType: "Bearer", expiresIn: 1234, refreshToken: "trt2", scope: nil), nil)
                }
            }
        }
        
        self.performExpectation(timeout: 4) { (e) in
            
            e.expectedFulfillmentCount = 5
            
            let manager = OAuth2IdentityManager(flow: Flow(e: e), refresher: nil, storage: InMemoryIdentityStorage(), authorizationMethod: .header)
            
            for _ in 0..<4 {
                
                manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!), handler: { (request, error) in
                    
                    XCTAssertNil(error)
                    XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer tat1")
                    e.fulfill()
                })
            }
        }
    }
    
    func testPerformingRequestsUsingStandartResponseValidator() {
        
        struct Flow: AuthorizationGrantFlow {
            
            let e: XCTestExpectation
            
            func authenticate(handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
                
                e.fulfill()
                handler(nil, nil)
            }
        }
        
        struct NClient: NetworkClient {
            
            let e: XCTestExpectation
            var statusCode: Int
            
            func perform(_ request: URLRequest, completion: @escaping (NetworkResponse) -> Void) {
                
                e.fulfill()
                completion(NetworkResponse(data: nil, response: HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil), error: nil))
            }
        }
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 12
            
            let manager: IdentityManager = OAuth2IdentityManager(flow: Flow(e: e), refresher: nil, storage: InMemoryIdentityStorage(), authorizationMethod: .header)
            
            var networkClient = NClient(e: e, statusCode: 111)
            
            //performing sohuld honor the instanace type
            //total of 3 fulfils should occur - 1 for flow, 1 for client and 1 for perform completion
            manager.perform(URLRequest(url: URL(string: "http://foo.bar")!), using: networkClient, retryAttempts: 3, completion: { (response) in
                
                e.fulfill()
            })
            
            //set the status code to fail
            networkClient.statusCode = 401
            
            //3 x retry attemtps (9) = 10 fulfils
            
            manager.perform(URLRequest(url: URL(string: "http://foo.bar")!), using: networkClient, retryAttempts: 3, completion: { (response) in
                
                e.fulfill()
            })
        }
    }
    
    func testPerformingRequestsUsingCustomResponseValidator() {
        
        struct Flow: AuthorizationGrantFlow {
            
            let e: XCTestExpectation
            
            func authenticate(handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
                
                e.fulfill()
                handler(nil, nil)
            }
        }
        
        struct NClient: NetworkClient {
            
            let e: XCTestExpectation
            var statusCode: Int
            
            func perform(_ request: URLRequest, completion: @escaping (NetworkResponse) -> Void) {
                
                e.fulfill()
                completion(NetworkResponse(data: nil, response: HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil), error: nil))
            }
        }
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 12
            
            let m = OAuth2IdentityManager(flow: Flow(e: e), refresher: nil, storage: InMemoryIdentityStorage(), authorizationMethod: .header)
            let manager: IdentityManager = m
            
            //set a custom response validator
            m.responseValidator = AnyNetworkResponseValidator(handler: { (response) -> Bool in
                
                return (response.response as? HTTPURLResponse)?.statusCode != 123
            })
            
            var networkClient = NClient(e: e, statusCode: 111)
            
            //performing sohuld honor the instanace type
            //total of 3 fulfils should occur - 1 for flow, 1 for client and 1 for perform completion
            manager.perform(URLRequest(url: URL(string: "http://foo.bar")!), using: networkClient, retryAttempts: 3, completion: { (response) in
                
                e.fulfill()
            })
            
            //set the status code to fail
            networkClient.statusCode = 123
            
            //3 x retry attemtps (9) = 10 fulfils
            
            manager.perform(URLRequest(url: URL(string: "http://foo.bar")!), using: networkClient, retryAttempts: 3, completion: { (response) in
                
                e.fulfill()
            })
        }
    }
    
    func testRefreshTokenStateUponRefreshFailureWithOAuth2Error() {
        
        //When trying to perform a refresh and the server returns an oauth2 error - the refresh token should be deleted
        
        class Flow: AuthorizationGrantFlow {
            
            func authenticate(handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
                
                handler(AccessTokenResponse(accessToken: "tat1", tokenType: "Bearer", expiresIn: 0, refreshToken: "trt1", scope: nil), nil)
            }
        }
        
        class Refresher: AccessTokenRefresher {
            
            func refresh(using requestModel: AccessTokenRefreshRequest, handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
                
                handler(nil, MHIdentityKitError.authenticationFailed(reason: MHIdentityKitError(error: ErrorResponse(code: .invalidGrant))))
            }
        }
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 2
            
            let manager = OAuth2IdentityManager(flow: Flow(), refresher: Refresher(), storage: InMemoryIdentityStorage(), authorizationMethod: .header)
            manager.forceAuthenticateOnRefreshError = false
            XCTAssertNil(manager.refreshToken)
            
            //upon first authorization - we don't have refresh token - so it will call the flow and save 1
            manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!), handler: { (request, error) in
                
                XCTAssertNil(error)
                XCTAssertEqual(manager.refreshToken, "trt1")
                e.fulfill()
            })
            
            //upon second authorization - we will have a refresh token and an error should be returned - the refresh token should be deleted
            manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!), handler: { (request, error) in
                
                XCTAssertNotNil(error)
                XCTAssertNil(manager.refreshToken)
                e.fulfill()
            })
        }
    }
    
    func testRefreshTokenStateUponRefreshFailureWithUnknownError() {
        
        //When trying to perform a refresh and the server returns an oauth2 error - the refresh token should be deleted
        
        class Flow: AuthorizationGrantFlow {
            
            func authenticate(handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
                
                handler(AccessTokenResponse(accessToken: "tat1", tokenType: "Bearer", expiresIn: 0, refreshToken: "trt1", scope: nil), nil)
            }
        }
        
        class Refresher: AccessTokenRefresher {
            
            func refresh(using requestModel: AccessTokenRefreshRequest, handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
                
                handler(nil, NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil))
            }
        }
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 2
            
            let manager = OAuth2IdentityManager(flow: Flow(), refresher: Refresher(), storage: InMemoryIdentityStorage(), authorizationMethod: .header)
            manager.forceAuthenticateOnRefreshError = false
            XCTAssertNil(manager.refreshToken)
            
            //upon first authorization - we don't have refresh token - so it will call the flow and save 1
            manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!), handler: { (request, error) in
                
                XCTAssertNil(error)
                XCTAssertEqual(manager.refreshToken, "trt1")
                e.fulfill()
            })
            
            //upon second authorization - we will have a refresh token and an error should be returned - the refresh token should be deleted
            manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!), handler: { (request, error) in
                
                XCTAssertNotNil(error)
                XCTAssertEqual(manager.refreshToken, "trt1")
                e.fulfill()
            })
        }
    }
    
    func testUsingIDToken() {
        
        XCTFail()
    }
}






