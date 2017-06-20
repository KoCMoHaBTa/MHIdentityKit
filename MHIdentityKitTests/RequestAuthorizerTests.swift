//
//  RequestAuthorizerTests.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 6/2/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import MHIdentityKit

class RequestAuthorizerTests: XCTestCase {
    
    func testHTTPBasicAuthorizer() {
        
        let authorizer: RequestAuthorizer = HTTPBasicAuthorizer(username: "tun", password: "tps")
        let request = URLRequest(url: URL(string: "http://foo.bar")!)
        
        self.performExpectation { (e) in
        
            authorizer.authorize(request: request) { (request, error) in
                
                XCTAssertNil(error)
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic dHVuOnRwcw==")
                
                e.fulfill()
            }
        }
    }
    
    func testBearerAccessTokenAuthorizerUsingHeader() {
        
        let authorizer: RequestAuthorizer = BearerAccessTokenAuthorizer(token: "test_token", method: .header)
        
        self.performExpectation { (e) in
            
            let request = URLRequest(url: URL(string: "http://foo.bar/test")!)
            
            authorizer.authorize(request: request, handler: { (request, error) in
                
                XCTAssertNil(error)
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test_token")
                
                e.fulfill()
            })
        }
    }
    
    func testBearerAccessTokenAuthorizerUsingBody() {
        
        let authorizer: RequestAuthorizer = BearerAccessTokenAuthorizer(token: "test_token", method: .body)
        
        self.performExpectation { (e) in
            
            let request = URLRequest(url: URL(string: "http://foo.bar")!)
            
            authorizer.authorize(request: request, handler: { (request, error) in
                
                XCTAssertNotNil(error)
                XCTAssertNil(request.httpBody)
                
                guard
                let error = error as? MHIdentityKitError,
                case MHIdentityKitError.authorizationFailed(let reason) = error,
                case MHIdentityKitError.Reason.invalidContentType = reason
                else {
                 
                    XCTFail()
                    return
                }
                
                e.fulfill()
            })
        }
        
        self.performExpectation { (e) in
            
            var request = URLRequest(url: URL(string: "http://foo.bar")!)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
            authorizer.authorize(request: request, handler: { (request, error) in
                
                XCTAssertNotNil(error)
                XCTAssertNil(request.httpBody)
                
                guard
                let error = error as? MHIdentityKitError,
                case MHIdentityKitError.authorizationFailed(let reason) = error,
                case MHIdentityKitError.Reason.invalidRequestMethod = reason
                else {
                    
                    XCTFail()
                    return
                }
                
                e.fulfill()
            })
        }
        
        self.performExpectation { (e) in
            
            var request = URLRequest(url: URL(string: "http://foo.bar")!)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            
            authorizer.authorize(request: request, handler: { (request, error) in
                
                XCTAssertNil(error)
                XCTAssertEqual(request.httpBody?.base64EncodedString(), "YWNjZXNzX3Rva2VuPXRlc3RfdG9rZW4=")
                
                e.fulfill()
            })
        }
        
        self.performExpectation { (e) in
            
            var request = URLRequest(url: URL(string: "http://foo.bar")!)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = "".data(using: .utf8)
            
            authorizer.authorize(request: request, handler: { (request, error) in
                
                XCTAssertNil(error)
                XCTAssertEqual(request.httpBody?.base64EncodedString(), "YWNjZXNzX3Rva2VuPXRlc3RfdG9rZW4=")
                
                e.fulfill()
            })
        }
        
        self.performExpectation { (e) in
            
            var request = URLRequest(url: URL(string: "http://foo.bar")!)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = "tdp=tdv".data(using: .utf8)
            
            authorizer.authorize(request: request, handler: { (request, error) in
                
                XCTAssertNil(error)
                XCTAssertEqual(request.httpBody?.base64EncodedString(), "dGRwPXRkdiZhY2Nlc3NfdG9rZW49dGVzdF90b2tlbg==")
                
                e.fulfill()
            })
        }
    }
    
    func testBearerAccessTokenAuthorizerUsingQuery() {
        
        let authorizer: RequestAuthorizer = BearerAccessTokenAuthorizer(token: "test_token", method: .query)
        
        self.performExpectation { (e) in
            
            let request = URLRequest(url: URL(string: "http://foo.bar")!)
            
            authorizer.authorize(request: request, handler: { (request, error) in
                
                XCTAssertNil(error)
                XCTAssertEqual(request.url?.absoluteString, "http://foo.bar?access_token=test_token")
                
                e.fulfill()
            })
        }
        
        self.performExpectation { (e) in
            
            let request = URLRequest(url: URL(string: "http://foo.bar/")!)
            
            authorizer.authorize(request: request, handler: { (request, error) in
                
                XCTAssertNil(error)
                XCTAssertEqual(request.url?.absoluteString, "http://foo.bar/?access_token=test_token")
                
                e.fulfill()
            })
        }
        
        self.performExpectation { (e) in
            
            let request = URLRequest(url: URL(string: "http://foo.bar/?")!)
            
            authorizer.authorize(request: request, handler: { (request, error) in
                
                XCTAssertNil(error)
                XCTAssertEqual(request.url?.absoluteString, "http://foo.bar/?access_token=test_token")
                
                e.fulfill()
            })
        }
        
        self.performExpectation { (e) in
            
            let request = URLRequest(url: URL(string: "http://foo.bar/test?")!)
            
            authorizer.authorize(request: request, handler: { (request, error) in
                
                XCTAssertNil(error)
                XCTAssertEqual(request.url?.absoluteString, "http://foo.bar/test?access_token=test_token")
                
                e.fulfill()
            })
        }
        
        self.performExpectation { (e) in
            
            let request = URLRequest(url: URL(string: "http://foo.bar/test?gg=5")!)
            
            authorizer.authorize(request: request, handler: { (request, error) in
                
                XCTAssertNil(error)
                XCTAssertEqual(request.url?.absoluteString, "http://foo.bar/test?gg=5&access_token=test_token")
                
                e.fulfill()
            })
        }
    }
    
    func testSynchronousAuthorization() {
        
        let authorizer: RequestAuthorizer = BearerAccessTokenAuthorizer(token: "test_token", method: .query)
        let request = try! URLRequest(url: URL(string: "http://foo.bar")!).authorized(using: authorizer)
        
        XCTAssertEqual(request.url?.absoluteString, "http://foo.bar?access_token=test_token")
    }
}
