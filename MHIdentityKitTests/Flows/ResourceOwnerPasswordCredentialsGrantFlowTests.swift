//
//  ResourceOwnerPasswordCredentialsGrantFlowTests.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 28.03.18.
//  Copyright © 2018 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import MHIdentityKit

class ResourceOwnerPasswordCredentialsGrantFlowTests: XCTestCase {
    
    let tokenEndpoint = URL(string: "http://foo.bar")!
    let scope: Scope = "read write"
    let clientAuthorizer = HTTPBasicAuthorizer(clientID: "tcid", secret: "ts")
    
    func testResourceOwnerPasswordCredentialsGrantFlow() async throws {
        
        var networkClientCallCount = 0
        let networkClient: NetworkClient = AnyNetworkClient { request in
            
            networkClientCallCount += 1
            
            XCTAssertEqual(request.url, self.tokenEndpoint)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic dGNpZDp0cw==")
            XCTAssertNotNil(request.httpBody)
            
            guard let parameters = request.httpBody?.urlDecodedParameters else {
                
                throw "Unable to decode body parameters"
            }
            
            XCTAssertEqual(parameters["grant_type"], "password")
            XCTAssertEqual(parameters["username"], "tu")
            XCTAssertEqual(parameters["password"], "tp")
            XCTAssertEqual(parameters["scope"], "read write")
            
            let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234,\"refresh_token\":\"trt\",\"scope\":\"ts1 ts2\"}".data(using: .utf8)!
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)!
            
            
            return NetworkResponse(data: data, response: response)
        }
        
        let credentialsProvider = AnyCredentialsProvider(username: "tu", password: "tp", didFinishAuthenticatingHandler: nil, didFailAuthenticatingHandler: { _ in
            
            XCTFail()
        })
        
        let flow: AuthorizationGrantFlow = ResourceOwnerPasswordCredentialsGrantFlow(
            tokenEndpoint: tokenEndpoint,
            credentialsProvider: credentialsProvider,
            scope: scope,
            clientAuthorizer: clientAuthorizer,
            networkClient: networkClient
        )
        
        let response = try await flow.authenticate()
        
        XCTAssertEqual(networkClientCallCount, 1)
        
        XCTAssertEqual(response.accessToken, "tat")
        XCTAssertEqual(response.tokenType, "ttt")
        XCTAssertEqual(response.expiresIn, 1234)
        XCTAssertEqual(response.refreshToken, "trt")
        XCTAssertEqual(response.scope?.rawValue, "ts1 ts2")
    }
    
    func testErrorFromNetworkClient() async throws {
        
        var networkClientCallCount = 0
        let networkClient: NetworkClient = AnyNetworkClient { request in
            
            networkClientCallCount += 1
            
            XCTAssertEqual(request.url, self.tokenEndpoint)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic dGNpZDp0cw==")
            XCTAssertNotNil(request.httpBody)
            
            guard let parameters = request.httpBody?.urlDecodedParameters else {
                
                throw "Unable to decode body parameters"
            }
            
            XCTAssertEqual(parameters["grant_type"], "password")
            XCTAssertEqual(parameters["username"], "tu")
            XCTAssertEqual(parameters["password"], "tp")
            XCTAssertEqual(parameters["scope"], "read write")
            
            let data = "{\"error\":\"invalid_client\"}".data(using: .utf8)!
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 400, httpVersion: nil, headerFields: nil)!
            
            return NetworkResponse(data: data, response: response)
        }
        
        let credentialsProvider = AnyCredentialsProvider(username: "tu", password: "tp", didFinishAuthenticatingHandler: {
            
            XCTFail()
            
        }, didFailAuthenticatingHandler: { (error) in
            
            XCTAssertEqual((error as? ErrorResponse)?.code, .invalidClient)
        })
        
        let flow: AuthorizationGrantFlow = ResourceOwnerPasswordCredentialsGrantFlow(
            tokenEndpoint: tokenEndpoint,
            credentialsProvider: credentialsProvider,
            scope: scope,
            clientAuthorizer: clientAuthorizer,
            networkClient: networkClient
        )
        
        do {
            _ = try await flow.authenticate()
            XCTFail("An error should be thrown")
        }
        catch let error as ErrorResponse where error.code == .invalidClient {}
    }
    
    func testAdditionalParameters() async throws {
        
        var networkClientCallCount = 0
        let networkClient: NetworkClient = AnyNetworkClient { request in
            
            networkClientCallCount += 1
            
            XCTAssertEqual(request.url, self.tokenEndpoint)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic dGNpZDp0cw==")
            XCTAssertNotNil(request.httpBody)
            
            guard let parameters = request.httpBody?.urlDecodedParameters else {
                
                throw "Unable to decode body parameters"
            }
            
            XCTAssertEqual(parameters["grant_type"], "password")
            XCTAssertEqual(parameters["username"], "tampered username")
            XCTAssertEqual(parameters["password"], "tp")
            XCTAssertEqual(parameters["scope"], "read write")
            XCTAssertEqual(parameters["additional_parameter"], "ap")
            
            let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234,\"refresh_token\":\"trt\",\"scope\":\"ts1 ts2\"}".data(using: .utf8)!
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)!
            
            
            return NetworkResponse(data: data, response: response)
        }
        
        let credentialsProvider = AnyCredentialsProvider(username: "tu", password: "tp", didFinishAuthenticatingHandler: nil, didFailAuthenticatingHandler: { (error) in
            
            XCTFail()
        })
        
        let flow = ResourceOwnerPasswordCredentialsGrantFlow(
            tokenEndpoint: tokenEndpoint,
            credentialsProvider: credentialsProvider,
            scope: scope,
            clientAuthorizer: clientAuthorizer,
            networkClient: networkClient
        )
        
        flow.additionalAccessTokenRequestParameters = ["additional_parameter": "ap", "username": "tampered username"]
        
        let response = try await flow.authenticate()
        
        XCTAssertEqual(networkClientCallCount, 1)
        
        XCTAssertEqual(response.accessToken, "tat")
        XCTAssertEqual(response.tokenType, "ttt")
        XCTAssertEqual(response.expiresIn, 1234)
        XCTAssertEqual(response.refreshToken, "trt")
        XCTAssertEqual(response.scope?.rawValue, "ts1 ts2")
        
        
    }
}





