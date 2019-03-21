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
    
    func testResourceOwnerPasswordCredentialsGrantFlow() {
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 3
            
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
                
                e.fulfill()
                
                
                let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234,\"refresh_token\":\"trt\",\"scope\":\"ts1 ts2\"}".data(using: .utf8)
                let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)
                
                
                handler(NetworkResponse(data: data, response: response, error: nil))
            }
            
            let credentialsProvider = AnyCredentialsProvider(username: "tu", password: "tp", didFinishAuthenticatingHandler: {
                
                e.fulfill()
                
            }, didFailAuthenticatingHandler: { (error) in
                
                XCTFail()
            })
            
            let flow: AuthorizationGrantFlow = ResourceOwnerPasswordCredentialsGrantFlow(tokenEndpoint: tokenEndpoint, credentialsProvider: credentialsProvider, scope: scope, clientAuthorizer: clientAuthorizer, networkClient: netoworkClient)
                
            flow.authenticate { (response, error) in
                
                XCTAssertNotNil(response)
                XCTAssertNil(error)
                
                XCTAssertEqual(response?.accessToken, "tat")
                XCTAssertEqual(response?.tokenType, "ttt")
                XCTAssertEqual(response?.expiresIn, 1234)
                XCTAssertEqual(response?.refreshToken, "trt")
                XCTAssertEqual(response?.scope?.value, "ts1 ts2")
                
                e.fulfill()
            }
        }
    }
    
    func testErrorFromNetworkClient() {
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 3
            
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
                
                e.fulfill()
                
                
                let data = "{\"error\":\"invalid_client\"}".data(using: .utf8)
                let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 400, httpVersion: nil, headerFields: nil)
                
                
                handler(NetworkResponse(data: data, response: response, error: nil))
            }
            
            let credentialsProvider = AnyCredentialsProvider(username: "tu", password: "tp", didFinishAuthenticatingHandler: {
                
                XCTFail()
                
            }, didFailAuthenticatingHandler: { (error) in
                
                XCTAssertEqual((error as? ErrorResponse)?.code, .invalidClient)
                e.fulfill()
            })
            
            let flow: AuthorizationGrantFlow = ResourceOwnerPasswordCredentialsGrantFlow(tokenEndpoint: tokenEndpoint, credentialsProvider: credentialsProvider, scope: scope, clientAuthorizer: clientAuthorizer, networkClient: netoworkClient)
            
            flow.authenticate { (response, error) in
                
                XCTAssertNil(response)
                XCTAssertNotNil(error)
                
                e.fulfill()
            }
        }
    }
    
    func testAdditionalParameters() {
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 3
            
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
                
                e.fulfill()
                
                
                let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234,\"refresh_token\":\"trt\",\"scope\":\"ts1 ts2\"}".data(using: .utf8)
                let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)
                
                
                handler(NetworkResponse(data: data, response: response, error: nil))
            }
            
            let credentialsProvider = AnyCredentialsProvider(username: "tu", password: "tp", didFinishAuthenticatingHandler: {
                
                e.fulfill()
                
            }, didFailAuthenticatingHandler: { (error) in
                
                XCTFail()
            })
            
            let flow = ResourceOwnerPasswordCredentialsGrantFlow(tokenEndpoint: tokenEndpoint, credentialsProvider: credentialsProvider, scope: scope, clientAuthorizer: clientAuthorizer, networkClient: netoworkClient)
            
            flow.additionalAccessTokenRequestParameters = ["additional_parameter": "ap", "username": "tampered username"]
            
            flow.authenticate { (response, error) in
                
                XCTAssertNotNil(response)
                XCTAssertNil(error)
                
                XCTAssertEqual(response?.accessToken, "tat")
                XCTAssertEqual(response?.tokenType, "ttt")
                XCTAssertEqual(response?.expiresIn, 1234)
                XCTAssertEqual(response?.refreshToken, "trt")
                XCTAssertEqual(response?.scope?.value, "ts1 ts2")
                
                e.fulfill()
            }
        }
    }
}





