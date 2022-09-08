//
//  ClientCredentialsGrantFlowAsyncTests.swift
//  MHIdentityKit
//
//  Created by Lyubomir Yordanov on 8/5/22.
//  Copyright © 2022 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import MHIdentityKit

@available(iOS 13, tvOS 13.0.0, macOS 10.15, *)
class ClientCredentialsGrantFlowAsyncTests: XCTestCase {
    
    let tokenEndpoint = URL(string: "http://foo.bar")!
    let credentialsProvider = AnyCredentialsProvider(username: "tu", password: "tp")
    let scope: Scope = "read write"
    let clientAuthorizer = HTTPBasicAuthorizer(clientID: "tcid", secret: "ts")
    
    func testClientCredentialsGrantFlowAsync() async {
        
        let netoworkClient: NetworkClient = TestNetworkClient { (request, handler) in
            
            XCTAssertEqual(request.url, self.tokenEndpoint)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic dGNpZDp0cw==")
            XCTAssertNotNil(request.httpBody)
            
            guard
                let parameters = request.httpBody?.urlDecodedParameters
            else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(parameters["grant_type"], "client_credentials")
            XCTAssertEqual(parameters["scope"], "read write")
            
            let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234}".data(using: .utf8)
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)
            
            handler(NetworkResponse(data: data, response: response, error: nil))
        }
        
        let flow: AuthorizationGrantFlow = ClientCredentialsGrantFlow(tokenEndpoint: tokenEndpoint, scope: scope, clientAuthorizer: clientAuthorizer, networkClient: netoworkClient)
        
        let response = try? await flow.authenticateAsync()
            
        XCTAssertNotNil(response)
        
        XCTAssertEqual(response?.accessToken, "tat")
        XCTAssertEqual(response?.tokenType, "ttt")
        XCTAssertEqual(response?.expiresIn, 1234)
        XCTAssertNil(response?.refreshToken)
        XCTAssertNil(response?.scope)
    }
    
    func testErrorDueToProvidedRefreshTokenAsync() async {
        
        let netoworkClient: NetworkClient = TestNetworkClient { (request, handler) in
            
            XCTAssertEqual(request.url, self.tokenEndpoint)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic dGNpZDp0cw==")
            XCTAssertNotNil(request.httpBody)
            
            guard
                let parameters = request.httpBody?.urlDecodedParameters
            else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(parameters["grant_type"], "client_credentials")
            XCTAssertEqual(parameters["scope"], "read write")
            
            let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234,\"refresh_token\":\"trt\"}".data(using: .utf8)
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)
            
            handler(NetworkResponse(data: data, response: response, error: nil))
        }
        
        let flow: AuthorizationGrantFlow = ClientCredentialsGrantFlow(tokenEndpoint: tokenEndpoint, scope: scope, clientAuthorizer: clientAuthorizer, networkClient: netoworkClient)
        
        let response = try? await flow.authenticateAsync()
            
        XCTAssertNil(response)
    }
    
    func testErrorFromNetworkClientAsync() async {
        
        let netoworkClient: NetworkClient = TestNetworkClient { (request, handler) in
            
            XCTAssertEqual(request.url, self.tokenEndpoint)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic dGNpZDp0cw==")
            XCTAssertNotNil(request.httpBody)
            
            guard
                let parameters = request.httpBody?.urlDecodedParameters
            else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(parameters["grant_type"], "client_credentials")
            XCTAssertEqual(parameters["scope"], "read write")
            
            let data = "{\"error\":\"invalid_grant\"}".data(using: .utf8)
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 400, httpVersion: nil, headerFields: nil)
            
            handler(NetworkResponse(data: data, response: response, error: nil))
        }
        
        let flow: AuthorizationGrantFlow = ClientCredentialsGrantFlow(tokenEndpoint: tokenEndpoint, scope: scope, clientAuthorizer: clientAuthorizer, networkClient: netoworkClient)
        
        let response = try? await flow.authenticateAsync()
        
        XCTAssertNil(response)
    }
    
    func testAdditionalParametersAsync() async {
        
        let netoworkClient: NetworkClient = TestNetworkClient { (request, handler) in
            
            XCTAssertEqual(request.url, self.tokenEndpoint)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic dGNpZDp0cw==")
            XCTAssertNotNil(request.httpBody)
            
            guard
                let parameters = request.httpBody?.urlDecodedParameters
            else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(parameters["grant_type"], "client_credentials")
            XCTAssertEqual(parameters["scope"], "tampered scope")
            XCTAssertEqual(parameters["additional_parameter"], "ap")
            
            let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234}".data(using: .utf8)
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)
            
            handler(NetworkResponse(data: data, response: response, error: nil))
        }
        
        let flow = ClientCredentialsGrantFlow(tokenEndpoint: tokenEndpoint, scope: scope, clientAuthorizer: clientAuthorizer, networkClient: netoworkClient)
        
        flow.additionalAccessTokenRequestParameters = ["additional_parameter": "ap", "scope": "tampered scope"]
        
        let response = try? await flow.authenticateAsync()
        
        XCTAssertNotNil(response)
        
        XCTAssertEqual(response?.accessToken, "tat")
        XCTAssertEqual(response?.tokenType, "ttt")
        XCTAssertEqual(response?.expiresIn, 1234)
        XCTAssertNil(response?.refreshToken)
        XCTAssertNil(response?.scope)
    }
}

