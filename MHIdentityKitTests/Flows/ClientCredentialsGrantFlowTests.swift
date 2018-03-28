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
    let credentialsProvider = DefaultCredentialsProvider(username: "tu", password: "tp")
    let scope: Scope = "read write"
    let clientAuthorizer = HTTPBasicAuthorizer(clientID: "tcid", secret: "ts")
    
    func testClientCredentialsGrantFlow() {
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 2
            
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
                
                e.fulfill()
                
                
                let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234}".data(using: .utf8)
                let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)
                
                handler(NetworkResponse(data: data, response: response, error: nil))
            }
            
            let flow: AuthorizationGrantFlow = ClientCredentialsGrantFlow(tokenEndpoint: tokenEndpoint, scope: scope, clientAuthorizer: clientAuthorizer, networkClient: netoworkClient)
                
            flow.authenticate(handler: { (response, error) in
                
                XCTAssertNotNil(response)
                XCTAssertNil(error)
                
                XCTAssertEqual(response?.accessToken, "tat")
                XCTAssertEqual(response?.tokenType, "ttt")
                XCTAssertEqual(response?.expiresIn, 1234)
                XCTAssertNil(response?.refreshToken)
                XCTAssertNil(response?.scope)
                
                e.fulfill()
            })
        }
    }
    
    func testErrorDueToProvidedRefreshToken() {
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 2
            
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
                
                e.fulfill()
                
                
                let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234,\"refresh_token\":\"trt\"}".data(using: .utf8)
                let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)
                
                handler(NetworkResponse(data: data, response: response, error: nil))
            }
            
            let flow: AuthorizationGrantFlow = ClientCredentialsGrantFlow(tokenEndpoint: tokenEndpoint, scope: scope, clientAuthorizer: clientAuthorizer, networkClient: netoworkClient)
            
            flow.authenticate(handler: { (response, error) in
                
                XCTAssertNil(response)
                XCTAssertNotNil(error)
                
                e.fulfill()
            })
        }
    }
    
    func testErrorFromNetworkClient() {
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 2
            
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
                
                e.fulfill()
                
                
                let data = "{\"error\":\"invalid_grant\"}".data(using: .utf8)
                let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 400, httpVersion: nil, headerFields: nil)
                
                handler(NetworkResponse(data: data, response: response, error: nil))
            }
            
            let flow: AuthorizationGrantFlow = ClientCredentialsGrantFlow(tokenEndpoint: tokenEndpoint, scope: scope, clientAuthorizer: clientAuthorizer, networkClient: netoworkClient)
            
            flow.authenticate(handler: { (response, error) in
                
                XCTAssertNil(response)
                XCTAssertNotNil(error)
                
                e.fulfill()
            })
        }
    }
}





