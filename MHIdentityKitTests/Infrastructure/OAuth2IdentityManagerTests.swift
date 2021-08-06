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
    
    func testOAuth2IdentityManager() async throws {

        class Flow: AuthorizationGrantFlow {
            
            private(set) var callCount = 0
            
            func authenticate() async throws -> AccessTokenResponse {
                
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
                    
                    throw OAuth2Error(code: .invalidGrant)
                }
            }
        }
        
        class Refresher: AccessTokenRefresher {
            
            private(set) var callCount = 0
            
            func refresh(using requestModel: AccessTokenRefreshRequest) async throws -> AccessTokenResponse {
                
                callCount += 1
                
                if callCount == 1 {
                    
                    XCTAssertEqual(requestModel.refreshToken, "trt1")
                    return AccessTokenResponse(accessToken: "rtat", tokenType: "Bearer", expiresIn: 0, refreshToken: "trt3", scope: nil)
                }
                else {
                    
                    XCTAssertEqual(requestModel.refreshToken, "trt3")
                    throw OAuth2Error(code: .invalidGrant)
                }
            }
        }
        
        let flow = Flow()
        let refresher = Refresher()
        let manager = OAuth2IdentityManager(flow: flow, refresher: refresher, storage: InMemoryIdentityStorage(), authorizationMethod: .header)
        let request = URLRequest(url: URL(string: "http://foo.bar")!)
        
        let authorizedRequest1 = try await manager.authorize(request: request, forceAuthenticate: false)
        XCTAssertEqual(authorizedRequest1.value(forHTTPHeaderField: "Authorization"), "Bearer tat1")
        
        let authorizedRequest2 = try await manager.authorize(request: request, forceAuthenticate: false)
        XCTAssertEqual(authorizedRequest2.value(forHTTPHeaderField: "Authorization"), "Bearer rtat")
        
        let authorizedRequest3 = try await manager.authorize(request: request, forceAuthenticate: false)
        XCTAssertEqual(authorizedRequest3.value(forHTTPHeaderField: "Authorization"), "Bearer tat2")
        
        let authorizedRequest4 = try await manager.authorize(request: request, forceAuthenticate: false)
        XCTAssertEqual(authorizedRequest4.value(forHTTPHeaderField: "Authorization"), "Bearer tat2")
        
        do {
            _ = try await manager.authorize(request: request, forceAuthenticate: true)
            XCTFail("An error should be thrown")
        }
        catch let error as OAuth2Error where error.code == .invalidGrant {}
        
        XCTAssertEqual(flow.callCount, 3)
        XCTAssertEqual(refresher.callCount, 2)
    }
    
    func testForceAuthenticateOnRefreshErrorTrue() async throws {
        
        class Flow: AuthorizationGrantFlow {
            
            func authenticate() async throws -> AccessTokenResponse {
                
                AccessTokenResponse(accessToken: "tat1", tokenType: "Bearer", expiresIn: 0, refreshToken: "trt1", scope: nil)
            }
        }
        
        class Refresher: AccessTokenRefresher {
            
            func refresh(using requestModel: AccessTokenRefreshRequest) async throws -> AccessTokenResponse {
                
                throw OAuth2Error(code: .invalidGrant)
            }
        }
        
        let manager = OAuth2IdentityManager(flow: Flow(), refresher: Refresher(), storage: InMemoryIdentityStorage(), authorizationMethod: .header)
        manager.forceAuthenticateOnRefreshError = true
        
        let request1 = try await manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!))
        XCTAssertEqual(request1.value(forHTTPHeaderField: "Authorization"), "Bearer tat1")
        
        let request2 = try await manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!))
        XCTAssertEqual(request2.value(forHTTPHeaderField: "Authorization"), "Bearer tat1")
    }
    
    func testForceAuthenticateOnRefreshErrorFalse() async throws {
        
        class Flow: AuthorizationGrantFlow {
            
            func authenticate() async throws -> AccessTokenResponse {
                
                AccessTokenResponse(accessToken: "tat1", tokenType: "Bearer", expiresIn: 0, refreshToken: "trt1", scope: nil)
            }
        }
        
        class Refresher: AccessTokenRefresher {
            
            func refresh(using requestModel: AccessTokenRefreshRequest) async throws -> AccessTokenResponse {
                
                throw OAuth2Error(code: .invalidGrant)
            }
        }
        
        let manager = OAuth2IdentityManager(flow: Flow(), refresher: Refresher(), storage: InMemoryIdentityStorage(), authorizationMethod: .header)
        manager.forceAuthenticateOnRefreshError = false
        
        let request1 = try await manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!))
        XCTAssertEqual(request1.value(forHTTPHeaderField: "Authorization"), "Bearer tat1")
        
        do {
            _ = try await manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!))
            XCTFail("An error should be thrown")
        }
        catch is OAuth2Error {}
    }
    
    func testSerialAuthorizationBehaviour() async throws {
        
        //if multiple authorization calls are made - only 1 should perform authentication :):)
        class Flow: AuthorizationGrantFlow {
            
            private(set) var callCount = 0
            
            func authenticate() async throws -> AccessTokenResponse {
                
                callCount += 1
                
                guard callCount == 1 else {
                    
                    throw "Flow authenticate should not be called more than once."
                }
                
                if #available(iOS 15.0, *) {
                    return await withCheckedContinuation { continuation in
                        
                        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + (2 * Double(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
                            
                            continuation.resume(returning: AccessTokenResponse(accessToken: "tat1", tokenType: "Bearer", expiresIn: 1234, refreshToken: "trt2", scope: nil))
                        }
                    }
                }
                else { fatalError("Xcode 13 Beta 1 requires iOS 15 for all async/await APIs ") }
            }
        }
        
        let flow = Flow()
        let manager = OAuth2IdentityManager(flow: flow, refresher: nil, storage: InMemoryIdentityStorage(), authorizationMethod: .header)
        
        async let request1 = try manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!))
        async let request2 = try manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!))
        async let request3 = try manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!))
        async let request4 = try manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!))
        async let request5 = try manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!))
        
        let requests = try await [request1, request2, request3, request4, request5]
        
        XCTAssertEqual(requests[0].value(forHTTPHeaderField: "Authorization"), "Bearer tat1")
        XCTAssertEqual(requests[1].value(forHTTPHeaderField: "Authorization"), "Bearer tat1")
        XCTAssertEqual(requests[2].value(forHTTPHeaderField: "Authorization"), "Bearer tat1")
        XCTAssertEqual(requests[3].value(forHTTPHeaderField: "Authorization"), "Bearer tat1")
        XCTAssertEqual(requests[4].value(forHTTPHeaderField: "Authorization"), "Bearer tat1")
        
        XCTAssertEqual(flow.callCount, 1)
    }
    
    func testPerformingRequestsUsingStandartResponseValidator() async throws {
        
        class Flow: AuthorizationGrantFlow {
            
            private(set) var callCount = 0
            
            func authenticate() async throws -> AccessTokenResponse {
                
                callCount += 1
                return .init(
                    accessToken: NSUUID().uuidString,
                    tokenType: NSUUID().uuidString,
                    expiresIn: nil,
                    refreshToken: nil,
                    scope: nil
                )
            }
        }
        
        class NClient: NetworkClient {
            
            private(set) var callCount = 0
            var statusCode: Int
            
            init(statusCode: Int) {
                
                self.statusCode = statusCode
            }
            
            func perform(_ request: URLRequest) async throws -> NetworkResponse {
                
                callCount += 1
                return .init(
                    data: .init(),
                    response: HTTPURLResponse(
                        url: request.url!,
                        statusCode: statusCode,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                )
            }
        }
        
        let flow = Flow()
        let manager: IdentityManager = OAuth2IdentityManager(flow: flow, refresher: nil, storage: InMemoryIdentityStorage(), authorizationMethod: .header)
        let networkClient = NClient(statusCode: 111)
        
        //performing sohuld honor the instanace type
        //step 1
        //total of 2 fulfils should occur - 1 for flow and 1 for client
        _ = try await manager.perform(URLRequest(url: URL(string: "http://foo.bar")!), using: networkClient, retryAttempts: 3)
        XCTAssertEqual(flow.callCount, 1)
        XCTAssertEqual(networkClient.callCount, 1)
        
        //set the status code to fail
        networkClient.statusCode = 401
        
        //step 2
        //NC: +3 for every retry attemtp and one final -> total of 4
        //Flow +3 for every forced retry
        _ = try await manager.perform(URLRequest(url: URL(string: "http://foo.bar")!), using: networkClient, retryAttempts: 3)
        XCTAssertEqual(flow.callCount, 4)
        XCTAssertEqual(networkClient.callCount, 5) // (1) from step 1 and (4) from step 2 = total of (5)
    }
    
    func testPerformingRequestsUsingCustomResponseValidator() async throws {
        
        class Flow: AuthorizationGrantFlow {
            
            private(set) var callCount = 0
            
            func authenticate() async throws -> AccessTokenResponse {
                
                callCount += 1
                return .init(
                    accessToken: NSUUID().uuidString,
                    tokenType: NSUUID().uuidString,
                    expiresIn: nil,
                    refreshToken: nil,
                    scope: nil
                )
            }
        }
        
        class NClient: NetworkClient {
            
            private(set) var callCount = 0
            var statusCode: Int
            
            init(statusCode: Int) {
                
                self.statusCode = statusCode
            }
            
            func perform(_ request: URLRequest) async throws -> NetworkResponse {
                
                callCount += 1
                return .init(
                    data: .init(),
                    response: HTTPURLResponse(
                        url: request.url!,
                        statusCode: statusCode,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                )
            }
        }
        
        let flow = Flow()
        let m = OAuth2IdentityManager(flow: flow, refresher: nil, storage: InMemoryIdentityStorage(), authorizationMethod: .header)
        
        //set a custom response validator
        m.responseValidator = AnyNetworkResponseValidator(handler: { (response) -> Bool in
            
            return (response.response as? HTTPURLResponse)?.statusCode != 123
        })
        
        let manager: IdentityManager = m
        let networkClient = NClient(statusCode: 111)
        
        //performing sohuld honor the instanace type
        //total of 2 fulfils should occur - 1 for flow and 1 for client
        _ = try await manager.perform(URLRequest(url: URL(string: "http://foo.bar")!), using: networkClient, retryAttempts: 3)
        XCTAssertEqual(flow.callCount, 1)
        XCTAssertEqual(networkClient.callCount, 1)
        
        //set the status code to fail
        networkClient.statusCode = 123
        
        //flow +3
        //NC: 1+3 for every retry attemtp
        _ = try await manager.perform(URLRequest(url: URL(string: "http://foo.bar")!), using: networkClient, retryAttempts: 3)
        XCTAssertEqual(flow.callCount, 4)
        XCTAssertEqual(networkClient.callCount, 5)
    }
    
    func testRefreshTokenStateUponRefreshFailureWithOAuth2Error() async throws {
        
        //When trying to perform a refresh and the server returns an oauth2 error - the refresh token should be deleted
        
        class Flow: AuthorizationGrantFlow {
            
            private(set) var callCount = 0
            
            func authenticate() async throws -> AccessTokenResponse {
                
                callCount += 1
                return AccessTokenResponse(accessToken: "tat1", tokenType: "Bearer", expiresIn: 0, refreshToken: "trt1", scope: nil)
            }
        }
        
        class Refresher: AccessTokenRefresher {
            
            private(set) var callCount = 0
            
            func refresh(using requestModel: AccessTokenRefreshRequest) async throws -> AccessTokenResponse {
                
                callCount += 1
                throw OAuth2Error(code: .invalidGrant)
            }
        }
        
        let flow = Flow()
        let refresher = Refresher()
        let manager = OAuth2IdentityManager(flow: flow, refresher: refresher, storage: InMemoryIdentityStorage(), authorizationMethod: .header)
        manager.forceAuthenticateOnRefreshError = false
        
        XCTAssertNil(manager.refreshToken)
        
        //upon first authorization - we don't have refresh token - so it will call the flow and save 1
        _ = try await manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!))
        XCTAssertEqual(manager.refreshToken, "trt1")
        XCTAssertEqual(flow.callCount, 1)
        XCTAssertEqual(refresher.callCount, 0)
        
        //upon second authorization - we will have a refresh token and an error should be returned - the refresh token should be deleted
        do {
            _ = try await manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!))
            XCTFail("An error should be thrown")
        }
        catch is OAuth2Error {}
        
        XCTAssertEqual(flow.callCount, 1)
        XCTAssertEqual(refresher.callCount, 1)
        XCTAssertNil(manager.refreshToken)
    }
    
    func testRefreshTokenStateUponRefreshFailureWithUnknownError() async throws {
        
        //When trying to perform a refresh and the server returns an oauth2 error - the refresh token should NOT be deleted
        
        class Flow: AuthorizationGrantFlow {
            
            private(set) var callCount = 0
            
            func authenticate() async throws -> AccessTokenResponse {
                
                callCount += 1
                return AccessTokenResponse(accessToken: "tat1", tokenType: "Bearer", expiresIn: 0, refreshToken: "trt1", scope: nil)
            }
        }
        
        class Refresher: AccessTokenRefresher {
            
            private(set) var callCount = 0
            
            func refresh(using requestModel: AccessTokenRefreshRequest) async throws -> AccessTokenResponse {
                
                callCount += 1
                throw NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
            }
        }
        
        let flow = Flow()
        let refresher = Refresher()
        let manager = OAuth2IdentityManager(flow: flow, refresher: refresher, storage: InMemoryIdentityStorage(), authorizationMethod: .header)
        manager.forceAuthenticateOnRefreshError = false
        XCTAssertNil(manager.refreshToken)
        
        //upon first authorization - we don't have refresh token - so it will call the flow and save 1
        _ = try await manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!))
        XCTAssertEqual(manager.refreshToken, "trt1")
        XCTAssertEqual(flow.callCount, 1)
        XCTAssertEqual(refresher.callCount, 0)
        
        //upon second authorization - we will have a refresh token and an error should be returned - the refresh token should not be deleted
        do {
            _ = try await manager.authorize(request: URLRequest(url: URL(string: "http://foo.bar")!))
            XCTFail("An error should be thrown")
        }
        catch let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet {}
        
        XCTAssertEqual(manager.refreshToken, "trt1")
        XCTAssertEqual(flow.callCount, 1)
        XCTAssertEqual(refresher.callCount, 1)
    }
    
    func testUsingIDToken() {
        
        XCTFail()
    }
}
