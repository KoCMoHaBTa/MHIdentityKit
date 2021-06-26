//
//  AccessTokenResponseHandler.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 6/1/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import MHIdentityKit

class AccessTokenResponseHandlerTests: XCTestCase {
    
    func testSuccess() async throws {
        
        let data = "{\"access_token\":\"gg\", \"token_type\":\"Bearer\", \"expires_in\": 1234, \"refresh_token\":\"rtgg\", \"scope\":\"read write\"}".data(using: .utf8)!
        let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let accessTokenResponse = try AccessTokenResponseHandler().handle(response: NetworkResponse(data: data, response: response))
        
        XCTAssertEqual(accessTokenResponse.accessToken, "gg")
        XCTAssertEqual(accessTokenResponse.tokenType, "Bearer")
        XCTAssertEqual(accessTokenResponse.expiresIn, 1234)
        XCTAssertEqual(accessTokenResponse.refreshToken, "rtgg")
        XCTAssertEqual(accessTokenResponse.scope?.rawValue, "read write")
    }
    
    func testMissingURLError() async throws {
        
        do {
            _ = try AccessTokenResponseHandler().handle(response: NetworkResponse(data: Data(), response: URLResponse()))
            XCTFail("An error should be thrown")
        }
        catch MHIdentityKitError.Reason.unknownURLResponse {}
    }
    
    func testOAuth2Error() async throws {
        
        do {
            let data = "{\"error\":\"invalid_grant\"}".data(using: .utf8)!
            let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 555, httpVersion: nil, headerFields: nil)!
            _ = try AccessTokenResponseHandler().handle(response: NetworkResponse(data: data, response: response))
            XCTFail("An error should be thrown")
        }
        catch let error as OAuth2Error where error.code == .invalidGrant {}
    }
    
    func testServerError() async throws {
        
        do {
            let data = "{}".data(using: .utf8)!
            let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 555, httpVersion: nil, headerFields: nil)!
            _ = try AccessTokenResponseHandler().handle(response: NetworkResponse(data: data, response: response))
            XCTFail("An error should be thrown")
        }
        catch MHIdentityKitError.Reason.unknownHTTPResponse(code: 555) {}
    }
    
    func testEmptyJSONError() async throws {
        
        do {
            let data = "{}".data(using: .utf8)!
            let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            _ = try AccessTokenResponseHandler().handle(response: NetworkResponse(data: data, response: response))
            XCTFail("An error should be thrown")
        }
        catch MHIdentityKitError.Reason.invalidAccessTokenResponse {}
    }
    
    func testAdditioanlParameteres() async throws {
        
        let data =
        """
        { "access_token":"gg", "token_type":"Bearer", "expires_in": 1234, "refresh_token":"rtgg", "scope":"read write", "custom_param1": true, "custom_str": "zagreo", "my_int": 5 }
        """
        .data(using: .utf8)!
        
        let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let accessTokenResponse = try AccessTokenResponseHandler().handle(response: NetworkResponse(data: data, response: response))
        
        XCTAssertEqual(accessTokenResponse.accessToken, "gg")
        XCTAssertEqual(accessTokenResponse.tokenType, "Bearer")
        XCTAssertEqual(accessTokenResponse.expiresIn, 1234)
        XCTAssertEqual(accessTokenResponse.refreshToken, "rtgg")
        XCTAssertEqual(accessTokenResponse.scope?.rawValue, "read write")
        XCTAssertEqual(accessTokenResponse.additionalParameters["custom_param1"] as? Bool, true)
        XCTAssertEqual(accessTokenResponse.additionalParameters["custom_str"] as? String, "zagreo")
        XCTAssertEqual(accessTokenResponse.additionalParameters["my_int"] as? Int, 5)
    }
    
    func testMissingRequiredParameters() async throws {
        
        do {
            let data =
            """
            { "access_token":"gg", "expires_in": 1234, "refresh_token":"rtgg", "scope":"read write", "custom_param1": true, "custom_str": "zagreo", "my_int": 5 }
            """
            .data(using: .utf8)!
            
            let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            _ = try AccessTokenResponseHandler().handle(response: NetworkResponse(data: data, response: response))
            XCTFail("An error should be thrown")
        }
        catch MHIdentityKitError.Reason.invalidAccessTokenResponse {}
    }
}
