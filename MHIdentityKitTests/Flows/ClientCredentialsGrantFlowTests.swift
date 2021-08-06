//
//  ClientCredentialsGrantFlowTests.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 28.03.18.
//  Copyright © 2018 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import MHIdentityKit

class ClientCredentialsGrantFlowTests: XCTestCase {
    
    let tokenEndpoint = URL(string: "http://foo.bar")!
    let credentialsProvider = AnyCredentialsProvider(username: "tu", password: "tp")
    let scope: Scope = "read write"
    let clientAuthorizer = HTTPBasicAuthorizer(clientID: "tcid", secret: "ts")
    
    func testClientCredentialsGrantFlow() async throws {
        
        var networkClientCallCount = 0
        let networkClient: NetworkClient = AnyNetworkClient { request in
            
            networkClientCallCount += 1
            
            XCTAssertEqual(request.url, self.tokenEndpoint)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic dGNpZDp0cw==")
            XCTAssertNotNil(request.httpBody)
            
            guard let parameters = request.httpBody?.urlDecodedParameters else {
                
                throw "Unable to decode body parameters"
            }
            
            XCTAssertEqual(parameters["grant_type"], "client_credentials")
            XCTAssertEqual(parameters["scope"], "read write")
            
            let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234}".data(using: .utf8)!
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)!
            
            return NetworkResponse(data: data, response: response)
        }
        
        let flow: AuthorizationGrantFlow = ClientCredentialsGrantFlow(
            tokenEndpoint: tokenEndpoint,
            scope: scope,
            clientAuthorizer: clientAuthorizer,
            networkClient: networkClient
        )
        
        let response = try await flow.authenticate()
        
        XCTAssertEqual(response.accessToken, "tat")
        XCTAssertEqual(response.tokenType, "ttt")
        XCTAssertEqual(response.expiresIn, 1234)
        XCTAssertNil(response.refreshToken)
        XCTAssertNil(response.scope)
        
        
    }
    
    func testErrorDueToProvidedRefreshToken() async throws {
        
        var networkClientCallCount = 0
        let networkClient: NetworkClient = AnyNetworkClient { request in
            
            networkClientCallCount += 1
            
            XCTAssertEqual(request.url, self.tokenEndpoint)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic dGNpZDp0cw==")
            XCTAssertNotNil(request.httpBody)
            
            guard let parameters = request.httpBody?.urlDecodedParameters else {
                
                throw "Unable to decode body parameters"
            }
            
            XCTAssertEqual(parameters["grant_type"], "client_credentials")
            XCTAssertEqual(parameters["scope"], "read write")
            
            let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234,\"refresh_token\":\"trt\"}".data(using: .utf8)!
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)!
            
            return NetworkResponse(data: data, response: response)
        }
        
        let flow: AuthorizationGrantFlow = ClientCredentialsGrantFlow(
            tokenEndpoint: tokenEndpoint,
            scope: scope,
            clientAuthorizer: clientAuthorizer,
            networkClient: networkClient
        )
        
        
        do {
            _ = try await flow.authenticate()
            XCTFail("An error should be thrown")
        }
        catch ClientCredentialsGrantFlow.Error.accessTokenResponseContainsRefreshToken {}
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
            
            XCTAssertEqual(parameters["grant_type"], "client_credentials")
            XCTAssertEqual(parameters["scope"], "read write")
            
            let data = "{\"error\":\"invalid_grant\"}".data(using: .utf8)!
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 400, httpVersion: nil, headerFields: nil)!
            
            return NetworkResponse(data: data, response: response)
        }
        
        let flow: AuthorizationGrantFlow = ClientCredentialsGrantFlow(tokenEndpoint: tokenEndpoint, scope: scope, clientAuthorizer: clientAuthorizer, networkClient: networkClient)
        
        do {
            _ = try await flow.authenticate()
            XCTFail("An error should be thrown")
        }
        catch let error as OAuth2Error where error.code == .invalidGrant {}
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
            
            XCTAssertEqual(parameters["grant_type"], "client_credentials")
            XCTAssertEqual(parameters["scope"], "tampered scope")
            XCTAssertEqual(parameters["additional_parameter"], "ap")
            
            let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234}".data(using: .utf8)!
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)!
            
            return NetworkResponse(data: data, response: response)
        }
        
        let flow = ClientCredentialsGrantFlow(tokenEndpoint: tokenEndpoint, scope: scope, clientAuthorizer: clientAuthorizer, networkClient: networkClient)
        
        flow.additionalAccessTokenRequestParameters = ["additional_parameter": "ap", "scope": "tampered scope"]
        
        let response = try await flow.authenticate()
        
        XCTAssertEqual(response.accessToken, "tat")
        XCTAssertEqual(response.tokenType, "ttt")
        XCTAssertEqual(response.expiresIn, 1234)
        XCTAssertNil(response.refreshToken)
        XCTAssertNil(response.scope)
    }
}





