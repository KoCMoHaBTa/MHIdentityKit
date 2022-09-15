//
//  RequestAuthorizerAsyncTests.swift
//  MHIdentityKit
//
//  Created by Lyubomir Yordanov on 8/5/22.
//  Copyright © 2022 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import MHIdentityKit

@available(iOS 13, tvOS 13.0.0, macOS 10.15, *)
class RequestAuthorizerAsyncTests: XCTestCase {
    
    func testHTTPBasicAuthorizer() async {
        
        let authorizer: RequestAuthorizer = HTTPBasicAuthorizer(username: "tun", password: "tps")
        let request = URLRequest(url: URL(string: "http://foo.bar")!)
        
        let urlRequest = try? await authorizer.authorize(request: request)
                
        XCTAssertEqual(urlRequest?.value(forHTTPHeaderField: "Authorization"), "Basic dHVuOnRwcw==")
    }
    
    func testBearerAccessTokenAuthorizerUsingHeader() async {
        
        let authorizer: RequestAuthorizer = BearerAccessTokenAuthorizer(token: "test_token", method: .header)
        
        let request = URLRequest(url: URL(string: "http://foo.bar/test")!)
        
        let urlRequest = try? await authorizer.authorize(request: request)
        
        XCTAssertEqual(urlRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer test_token")
    }
    
    func testBearerAccessTokenAuthorizerUsingBody() async {
        
        let authorizer: RequestAuthorizer = BearerAccessTokenAuthorizer(token: "test_token", method: .body)
        
        let request = URLRequest(url: URL(string: "http://foo.bar")!)
        
        do {
            
            let urlRequest = try await authorizer.authorize(request: request)
            XCTAssertNil(urlRequest.httpBody)
        }
        catch {
            
            guard
                let error = error as? MHIdentityKitError,
                case MHIdentityKitError.authorizationFailed(let reason) = error,
                case MHIdentityKitError.Reason.invalidContentType = reason
            else {
                
                XCTFail()
                return
            }
        }
        
        var request2 = URLRequest(url: URL(string: "http://foo.bar")!)
        request2.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        do {
            
            let urlRequest2 = try await authorizer.authorize(request: request2)
            XCTAssertNil(urlRequest2.httpBody)
        }
        catch {
            
            guard
                let error = error as? MHIdentityKitError,
                case MHIdentityKitError.authorizationFailed(let reason) = error,
                case MHIdentityKitError.Reason.invalidRequestMethod = reason
            else {
                
                XCTFail()
                return
            }
        }
        
        var request3 = URLRequest(url: URL(string: "http://foo.bar")!)
        request3.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request3.httpMethod = "POST"
        
        let urlRequest3 = try? await authorizer.authorize(request: request3)
        
        XCTAssertEqual(urlRequest3?.httpBody?.base64EncodedString(), "YWNjZXNzX3Rva2VuPXRlc3RfdG9rZW4=")
        
        var request4 = URLRequest(url: URL(string: "http://foo.bar")!)
        request4.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request4.httpMethod = "POST"
        request4.httpBody = "".data(using: .utf8)
        
        let urlRequest4 = try? await authorizer.authorize(request: request4)
        
        XCTAssertEqual(urlRequest4?.httpBody?.base64EncodedString(), "YWNjZXNzX3Rva2VuPXRlc3RfdG9rZW4=")
        
        var request5 = URLRequest(url: URL(string: "http://foo.bar")!)
        request5.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request5.httpMethod = "POST"
        request5.httpBody = "tdp=tdv".data(using: .utf8)
        
        let urlRequest5 = try? await authorizer.authorize(request: request5)
        
        XCTAssertEqual(urlRequest5?.httpBody?.base64EncodedString(), "dGRwPXRkdiZhY2Nlc3NfdG9rZW49dGVzdF90b2tlbg==")
    }
    
    func testBearerAccessTokenAuthorizerUsingQuery() async {
        
        let authorizer: RequestAuthorizer = BearerAccessTokenAuthorizer(token: "test_token", method: .query)
        
        let request = URLRequest(url: URL(string: "http://foo.bar")!)
        let urlRequest = try? await authorizer.authorize(request: request)
                
        XCTAssertEqual(urlRequest?.url?.absoluteString, "http://foo.bar?access_token=test_token")
        
        let request2 = URLRequest(url: URL(string: "http://foo.bar/")!)
        let urlRequest2 = try? await authorizer.authorize(request: request2)
        
        XCTAssertEqual(urlRequest2?.url?.absoluteString, "http://foo.bar/?access_token=test_token")
        
        let request3 = URLRequest(url: URL(string: "http://foo.bar/?")!)
        let urlRequest3 = try? await authorizer.authorize(request: request3)
        
        XCTAssertEqual(urlRequest3?.url?.absoluteString, "http://foo.bar/?access_token=test_token")
        
        let request4 = URLRequest(url: URL(string: "http://foo.bar/test?")!)
        let urlRequest4 = try? await authorizer.authorize(request: request4)
        
        XCTAssertEqual(urlRequest4?.url?.absoluteString, "http://foo.bar/test?access_token=test_token")
              
        let request5 = URLRequest(url: URL(string: "http://foo.bar/test?gg=5")!)
        let urlRequest5 = try? await authorizer.authorize(request: request5)
        
        XCTAssertEqual(urlRequest5?.url?.absoluteString, "http://foo.bar/test?gg=5&access_token=test_token")
    }
}
