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
    
    func testHTTPBasicAuthorizer() async throws {
        
        let authorizer: RequestAuthorizer = HTTPBasicAuthorizer(username: "tun", password: "tps")
        let request = URLRequest(url: URL(string: "http://foo.bar")!)
        let authorizedRequest = try await authorizer.authorize(request: request)
        
        XCTAssertEqual(authorizedRequest.value(forHTTPHeaderField: "Authorization"), "Basic dHVuOnRwcw==")
    }
    
    func testBearerAccessTokenAuthorizerUsingHeader() async throws {
        
        let authorizer: RequestAuthorizer = BearerAccessTokenAuthorizer(token: "test_token", method: .header)
        let request = URLRequest(url: URL(string: "http://foo.bar/test")!)
        let authorizedRequest = try await authorizer.authorize(request: request)
        
        XCTAssertEqual(authorizedRequest.value(forHTTPHeaderField: "Authorization"), "Bearer test_token")
    }
    
    func testBearerAccessTokenAuthorizerUsingBodyWithInvalidContentType() async throws {
        
        do {
            let authorizer: RequestAuthorizer = BearerAccessTokenAuthorizer(token: "test_token", method: .body)
            let request = URLRequest(url: URL(string: "http://foo.bar")!)
            _ = try await authorizer.authorize(request: request)
            XCTFail("An error should be thrown")
        }
        catch MHIdentityKitError.authorizationFailed(reason: MHIdentityKitError.Reason.invalidContentType) {}
    }
    
    func testBearerAccessTokenAuthorizerUsingBodyWithInvalidRequestMethod() async throws {
        
        do {
            let authorizer: RequestAuthorizer = BearerAccessTokenAuthorizer(token: "test_token", method: .body)
            var request = URLRequest(url: URL(string: "http://foo.bar")!)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            _ = try await authorizer.authorize(request: request)
            XCTFail("An error should be thrown")
        }
        catch MHIdentityKitError.authorizationFailed(reason: MHIdentityKitError.Reason.invalidRequestMethod) {}
    }
    
    func testBearerAccessTokenAuthorizerUsingNilBody() async throws {
        
        let authorizer: RequestAuthorizer = BearerAccessTokenAuthorizer(token: "test_token", method: .body)
        
        var request = URLRequest(url: URL(string: "http://foo.bar")!)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        let authorizedRequest = try await authorizer.authorize(request: request)
        
        XCTAssertEqual(authorizedRequest.httpBody?.base64EncodedString(), "YWNjZXNzX3Rva2VuPXRlc3RfdG9rZW4=")
    }
    
    func testBearerAccessTokenAuthorizerUsingEmptyBody() async throws {
        
        let authorizer: RequestAuthorizer = BearerAccessTokenAuthorizer(token: "test_token", method: .body)
        
        var request = URLRequest(url: URL(string: "http://foo.bar")!)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = "".data(using: .utf8)
        
        let authorizedRequest = try await authorizer.authorize(request: request)
        
        XCTAssertEqual(authorizedRequest.httpBody?.base64EncodedString(), "YWNjZXNzX3Rva2VuPXRlc3RfdG9rZW4=")
    }
    
    func testBearerAccessTokenAuthorizerUsingBody() async throws {
        
        let authorizer: RequestAuthorizer = BearerAccessTokenAuthorizer(token: "test_token", method: .body)
        
        var request = URLRequest(url: URL(string: "http://foo.bar")!)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = "tdp=tdv".data(using: .utf8)
        
        let authorizedRequest = try await authorizer.authorize(request: request)
        
        XCTAssertEqual(authorizedRequest.httpBody?.base64EncodedString(), "dGRwPXRkdiZhY2Nlc3NfdG9rZW49dGVzdF90b2tlbg==")
    }
    
    func testBearerAccessTokenAuthorizerUsingEmptyQueryNoTrailingSlash() async throws {
        
        let authorizer: RequestAuthorizer = BearerAccessTokenAuthorizer(token: "test_token", method: .query)
        let request = try await URLRequest(url: URL(string: "http://foo.bar")!).authorized(using: authorizer)
        
        XCTAssertEqual(request, URLRequest(url: URL(string: "http://foo.bar?access_token=test_token")!))
    }
    
    func testBearerAccessTokenAuthorizerUsingEmptyQueryWithTrailingSlash() async throws {
        
        let authorizer: RequestAuthorizer = BearerAccessTokenAuthorizer(token: "test_token", method: .query)
        let request = try await URLRequest(url: URL(string: "http://foo.bar/")!).authorized(using: authorizer)
        
        XCTAssertEqual(request, URLRequest(url: URL(string: "http://foo.bar/?access_token=test_token")!))
    }
    
    func testBearerAccessTokenAuthorizerUsingEmptyQueryWithTrailingQuestionMark() async throws {
        
        let authorizer: RequestAuthorizer = BearerAccessTokenAuthorizer(token: "test_token", method: .query)
        let request = try await URLRequest(url: URL(string: "http://foo.bar/?")!).authorized(using: authorizer)
        
        XCTAssertEqual(request, URLRequest(url: URL(string: "http://foo.bar/?access_token=test_token")!))
    }
    
    func testBearerAccessTokenAuthorizerUsingEmptyQueryWithTrailingQuestionMarkAndPath() async throws {
        
        let authorizer: RequestAuthorizer = BearerAccessTokenAuthorizer(token: "test_token", method: .query)
        let request = try await URLRequest(url: URL(string: "http://foo.bar/test?")!).authorized(using: authorizer)
        
        XCTAssertEqual(request, URLRequest(url: URL(string: "http://foo.bar/test?access_token=test_token")!))
    }
    
    func testBearerAccessTokenAuthorizerUsingQuery() async throws {
        
        let authorizer: RequestAuthorizer = BearerAccessTokenAuthorizer(token: "test_token", method: .query)
        let request = try await URLRequest(url: URL(string: "http://foo.bar/test?gg=5")!).authorized(using: authorizer)
        
        XCTAssertEqual(request, URLRequest(url: URL(string: "http://foo.bar/test?gg=5&access_token=test_token")!))
    }
}
