//
//  AuthorizationGrantFlowTests.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 6/5/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import MHIdentityKit

class AuthorizationGrantFlowTests: XCTestCase {
    
    let tokenEndpoint = URL(string: "http://foo.bar")!
    let credentialsProvider = DefaultCredentialsProvider(username: "tu", password: "tp")
    let scope: Scope = "read write"
    let clientAuthorizer = HTTPBasicAuthorizer(clientID: "tcid", secret: "ts")
    
    func testResourceOwnerPasswordCredentialsGrantFlow() {

        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 2
            
            let netoworkClient = TestNetworkClient { (request, handler) in
                
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
                XCTAssertEqual(parameters["scope"], self.scope.value)
                
                e.fulfill()
                
                
                let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234,\"refresh_token\":\"trt\",\"scope\":\"ts1 ts2\"}".data(using: .utf8)
                let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)
                
                
                handler(NetworkResponse(data: data, response: response, error: nil))
            }
            
            ResourceOwnerPasswordCredentialsGrantFlow(tokenEndpoint: self.tokenEndpoint, credentialsProvider: self.credentialsProvider, scope: self.scope, clientAuthorizer: self.clientAuthorizer, networkClient: netoworkClient).authenticate { (response, error) in
                
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
    
    func testClientCredentialsGrantFlow() {
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 2
            
            let netoworkClient = TestNetworkClient { (request, handler) in
                
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
                XCTAssertEqual(parameters["scope"], self.scope.value)
                
                e.fulfill()
                
                
                let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234}".data(using: .utf8)
                let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)
                
                handler(NetworkResponse(data: data, response: response, error: nil))
            }
            
            ClientCredentialsGrantFlow(tokenEndpoint: self.tokenEndpoint, scope: self.scope, networkClient: netoworkClient, clientAuthorizer: self.clientAuthorizer).authenticate(handler: { (response, error) in
                
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
}





