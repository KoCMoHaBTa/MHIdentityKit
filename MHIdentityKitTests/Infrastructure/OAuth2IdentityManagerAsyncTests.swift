//
//  OAuth2IdentityManagerAsyncTests.swift
//  MHIdentityKit
//
//  Created by Lyubomir Yordanov on 8/2/22.
//  Copyright © 2022 Milen Halachev. All rights reserved.
//

import Foundation

import XCTest
@testable import MHIdentityKit

@available(iOS 13.0.0, *)
class OAuth2IdentityManagerAsyncTests: XCTestCase {
    
    func testOAuth2IdentityManagerAsync() async {
        
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
            
            func authenticateAsync() async throws -> AccessTokenResponse? {
                
                e.fulfill()
                callCount += 1
                
                if callCount == 1 {
                    
                    //simulate expired token
                    return AccessTokenResponse(accessToken: "tat1", tokenType: "Bearer", expiresIn: 0, refreshToken: "trt1", scope: nil)
                }
                else if callCount == 2 {
                    
                    //simulate valid token
                    return AccessTokenResponse(accessToken: "tat2", tokenType: "Bearer", expiresIn: 1234, refreshToken: "trt2", scope: nil)
                }
                else {
                    
                    throw ErrorResponse(code: .invalidGrant)
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
        
        let manager = OAuth2IdentityManager(flow: Flow(e: XCTestExpectation(description: "XCTestCase Default Expectation")), refresher: Refresher(e: XCTestExpectation(description: "XCTestCase Default Expectation")), storage: InMemoryIdentityStorage(), authorizationMethod: .header)
        
        let request1 = try! await manager.authorizeAsync(request: URLRequest(url: URL(string: "http://foo.bar")!), forceAuthenticate: false)
        XCTAssertEqual(request1.value(forHTTPHeaderField: "Authorization"), "Bearer tat1")
        
        let request2 = try! await manager.authorizeAsync(request: URLRequest(url: URL(string: "http://foo.bar")!), forceAuthenticate: false)
        XCTAssertEqual(request2.value(forHTTPHeaderField: "Authorization"), "Bearer rtat")
        
        let request3 = try! await manager.authorizeAsync(request: URLRequest(url: URL(string: "http://foo.bar")!), forceAuthenticate: false)
        XCTAssertEqual(request3.value(forHTTPHeaderField: "Authorization"), "Bearer tat2")
        
        let request4 = try! await manager.authorizeAsync(request: URLRequest(url: URL(string: "http://foo.bar")!), forceAuthenticate: false)
        XCTAssertEqual(request4.value(forHTTPHeaderField: "Authorization"), "Bearer tat2")
        
        let request5 = try? await manager.authorizeAsync(request: URLRequest(url: URL(string: "http://foo.bar")!), forceAuthenticate: true)
        XCTAssertNil(request5?.value(forHTTPHeaderField: "Authorization"))
    }
    
    func testPerformingRequestsUsingCustomResponseValidatorAsync() async {
        
        struct Flow: AuthorizationGrantFlow {
            
            let e: XCTestExpectation
            
            func authenticate(handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
                
                e.fulfill()
                handler(nil, nil)
            }
            
            func authenticateAsync() async throws -> AccessTokenResponse? {
                
                e.fulfill()
                return nil
            }
        }
        
        struct NClient: NetworkClient {
            
            let e: XCTestExpectation
            var statusCode: Int
            
            func perform(_ request: URLRequest, completion: @escaping (NetworkResponse) -> Void) {
                
                e.fulfill()
                completion(NetworkResponse(data: nil, response: HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil), error: nil))
            }
            
            func performAsync(_ request: URLRequest) async -> NetworkResponse {
                
                e.fulfill()
                return NetworkResponse(data: nil, response: HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil), error: nil)
            }
        }
        
        let e = XCTestExpectation(description: "XCTestCase Default Expectation")
        
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
        _ = try! await manager.performAsync(URLRequest(url: URL(string: "http://foo.bar")!), using: networkClient, retryAttempts: 3)
        e.fulfill()
        
        //set the status code to fail
        networkClient.statusCode = 123
        
        //3 x retry attemtps (9) = 10 fulfils
        
        _ = try! await manager.performAsync(URLRequest(url: URL(string: "http://foo.bar")!), using: networkClient, retryAttempts: 3)
        e.fulfill()
    }
    
    func testRefreshTokenStateUponRefreshFailureWithUnknownErrorAsync() async {
        
        //When trying to perform a refresh and the server returns an oauth2 error - the refresh token should be deleted
        
        class Flow: AuthorizationGrantFlow {
            
            func authenticate(handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
                
                handler(AccessTokenResponse(accessToken: "tat1", tokenType: "Bearer", expiresIn: 0, refreshToken: "trt1", scope: nil), nil)
            }
            
            func authenticateAsync() async throws -> AccessTokenResponse? {
                
                return AccessTokenResponse(accessToken: "tat1", tokenType: "Bearer", expiresIn: 0, refreshToken: "trt1", scope: nil)
            }
        }
        
        class Refresher: AccessTokenRefresher {
            
            func refresh(using requestModel: AccessTokenRefreshRequest, handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
                
                handler(nil, NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil))
            }
        }
        
        let e = XCTestExpectation(description: "XCTestCase Default Expectation")
        
        e.expectedFulfillmentCount = 2
        
        let manager = OAuth2IdentityManager(flow: Flow(), refresher: Refresher(), storage: InMemoryIdentityStorage(), authorizationMethod: .header)
        manager.forceAuthenticateOnRefreshError = false
        XCTAssertNil(manager.refreshToken)
        
        //upon first authorization - we don't have refresh token - so it will call the flow and save 1
        let request = try? await manager.authorizeAsync(request: URLRequest(url: URL(string: "http://foo.bar")!))
        XCTAssertNotNil(request)
        XCTAssertEqual(manager.refreshToken, "trt1")
        e.fulfill()
        
        //upon second authorization - we will have a refresh token and an error should be returned - the refresh token should be deleted
        let secondRequest = try? await manager.authorizeAsync(request: URLRequest(url: URL(string: "http://foo.bar")!))
        XCTAssertNil(secondRequest)
        XCTAssertEqual(manager.refreshToken, "trt1")
        e.fulfill()
    }
}
