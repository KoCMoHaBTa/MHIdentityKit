//
//  ResourceOwnerPasswordCredentialsGrantFlowAsyncTests.swift
//  MHIdentityKit
//
//  Created by Lyubomir Yordanov on 8/3/22.
//  Copyright © 2022 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import MHIdentityKit

@available(iOS 13, tvOS 13.0.0, macOS 10.15, *)
class ResourceOwnerPasswordCredentialsGrantFlowAsyncTests: XCTestCase {
    
    let tokenEndpoint = URL(string: "http://foo.bar")!
    let scope: Scope = "read write"
    let clientAuthorizer = HTTPBasicAuthorizer(clientID: "tcid", secret: "ts")
    
    func testResourceOwnerPasswordCredentialsGrantFlow() async {
        
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
            
            XCTAssertEqual(parameters["grant_type"], "password")
            XCTAssertEqual(parameters["username"], "tu")
            XCTAssertEqual(parameters["password"], "tp")
            XCTAssertEqual(parameters["scope"], "read write")
            
            let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234,\"refresh_token\":\"trt\",\"scope\":\"ts1 ts2\"}".data(using: .utf8)
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)
            
            
            handler(NetworkResponse(data: data, response: response, error: nil))
        }
        
        let credentialsProvider = AnyCredentialsProvider(username: "tu", password: "tp", didFinishAuthenticatingHandler: {
            
        }, didFailAuthenticatingHandler: { (error) in
            
            XCTFail()
        })
        
        let flow: AuthorizationGrantFlow = ResourceOwnerPasswordCredentialsGrantFlow(tokenEndpoint: tokenEndpoint, credentialsProvider: credentialsProvider, scope: scope, clientAuthorizer: clientAuthorizer, networkClient: netoworkClient)
            
        let response = try? await flow.authenticate()
            
        XCTAssertNotNil(response)
        
        XCTAssertEqual(response?.accessToken, "tat")
        XCTAssertEqual(response?.tokenType, "ttt")
        XCTAssertEqual(response?.expiresIn, 1234)
        XCTAssertEqual(response?.refreshToken, "trt")
        XCTAssertEqual(response?.scope?.value, "ts1 ts2")
    }
    
    func testErrorFromNetworkClient() async {
        
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
            
            XCTAssertEqual(parameters["grant_type"], "password")
            XCTAssertEqual(parameters["username"], "tu")
            XCTAssertEqual(parameters["password"], "tp")
            XCTAssertEqual(parameters["scope"], "read write")
            
            let data = "{\"error\":\"invalid_client\"}".data(using: .utf8)
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 400, httpVersion: nil, headerFields: nil)
            
            
            handler(NetworkResponse(data: data, response: response, error: nil))
        }
        
        let credentialsProvider = AnyCredentialsProvider(username: "tu", password: "tp", didFinishAuthenticatingHandler: {
            
            XCTFail()
            
        }, didFailAuthenticatingHandler: { (error) in
            
            XCTAssertEqual((error as? ErrorResponse)?.code, .invalidClient)
        })
        
        let flow: AuthorizationGrantFlow = ResourceOwnerPasswordCredentialsGrantFlow(tokenEndpoint: tokenEndpoint, credentialsProvider: credentialsProvider, scope: scope, clientAuthorizer: clientAuthorizer, networkClient: netoworkClient)
        
        let response = try? await flow.authenticate()
            
        XCTAssertNil(response)
    }
    
    func testAdditionalParameters() async {
        
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
            
            XCTAssertEqual(parameters["grant_type"], "password")
            XCTAssertEqual(parameters["username"], "tampered username")
            XCTAssertEqual(parameters["password"], "tp")
            XCTAssertEqual(parameters["scope"], "read write")
            XCTAssertEqual(parameters["additional_parameter"], "ap")
            
            let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234,\"refresh_token\":\"trt\",\"scope\":\"ts1 ts2\"}".data(using: .utf8)
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)
            
            
            handler(NetworkResponse(data: data, response: response, error: nil))
        }
        
        let credentialsProvider = AnyCredentialsProvider(username: "tu", password: "tp", didFinishAuthenticatingHandler: {
            
        }, didFailAuthenticatingHandler: { (error) in
            
            XCTFail()
        })
        
        let flow = ResourceOwnerPasswordCredentialsGrantFlow(tokenEndpoint: tokenEndpoint, credentialsProvider: credentialsProvider, scope: scope, clientAuthorizer: clientAuthorizer, networkClient: netoworkClient)
        
        flow.additionalAccessTokenRequestParameters = ["additional_parameter": "ap", "username": "tampered username"]
        
        let response = try? await flow.authenticate()
            
        XCTAssertNotNil(response)
            
        XCTAssertEqual(response?.accessToken, "tat")
        XCTAssertEqual(response?.tokenType, "ttt")
        XCTAssertEqual(response?.expiresIn, 1234)
        XCTAssertEqual(response?.refreshToken, "trt")
        XCTAssertEqual(response?.scope?.value, "ts1 ts2")
    }
}
