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

class AccessTokenResponseTests: XCTestCase {
    
    func testSuccess() throws {
        
        let data = "{\"access_token\":\"gg\", \"token_type\":\"Bearer\", \"expires_in\": 1234, \"refresh_token\":\"rtgg\", \"scope\":\"read write\"}".data(using: .utf8)!
        let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let accessTokenResponse = try AccessTokenResponse(from: NetworkResponse(data: data, response: response))
        
        XCTAssertEqual(accessTokenResponse.accessToken, "gg")
        XCTAssertEqual(accessTokenResponse.tokenType, "Bearer")
        XCTAssertEqual(accessTokenResponse.expiresIn, 1234)
        XCTAssertEqual(accessTokenResponse.refreshToken, "rtgg")
        XCTAssertEqual(accessTokenResponse.scope?.rawValue, "read write")
    }
    
    func testMissingURLError() throws {
        
        do {
            _ = try AccessTokenResponse(from: NetworkResponse(data: Data(), response: URLResponse()))
            XCTFail("An error should be thrown")
        }
        catch AccessTokenResponse.Error.invalidURLResponseType {}
    }
    
    func testOAuth2Error() throws {
        
        do {
            let data = "{\"error\":\"invalid_grant\"}".data(using: .utf8)!
            let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 555, httpVersion: nil, headerFields: nil)!
            _ = try AccessTokenResponse(from: NetworkResponse(data: data, response: response))
            XCTFail("An error should be thrown")
        }
        catch let error as OAuth2Error where error.code == .invalidGrant {}
    }
    
    func testServerError() throws {
        
        do {
            let data = "{}".data(using: .utf8)!
            let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 555, httpVersion: nil, headerFields: nil)!
            _ = try AccessTokenResponse(from: NetworkResponse(data: data, response: response))
            XCTFail("An error should be thrown")
        }
        catch AccessTokenResponse.Error.invalidHTTPStatusCode(555) {}
    }
    
    func testMissingAccessTokenError() throws {
        
        do {
            let data = "{}".data(using: .utf8)!
            let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            _ = try AccessTokenResponse(from: NetworkResponse(data: data, response: response))
            XCTFail("An error should be thrown")
        }
        catch AccessTokenResponse.Error.invalidAccessToken {}
    }
    
    func testInvalidAccessTokenError() throws {
        
        do {
            let data = "{\"access_token\":65}".data(using: .utf8)!
            let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            _ = try AccessTokenResponse(from: NetworkResponse(data: data, response: response))
            XCTFail("An error should be thrown")
        }
        catch AccessTokenResponse.Error.invalidAccessToken {}
    }
    
    func testMissingTokenTypeError() throws {
        
        do {
            let data = "{\"access_token\":\"gg\"}".data(using: .utf8)!
            let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            _ = try AccessTokenResponse(from: NetworkResponse(data: data, response: response))
            XCTFail("An error should be thrown")
        }
        catch AccessTokenResponse.Error.invalidTokenType {}
    }
    
    func testInvalidTokenTypeError() throws {
        
        do {
            let data = "{\"access_token\":\"gg\", \"token_type\":65}".data(using: .utf8)!
            let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            _ = try AccessTokenResponse(from: NetworkResponse(data: data, response: response))
            XCTFail("An error should be thrown")
        }
        catch AccessTokenResponse.Error.invalidTokenType {}
    }
    
    func testAdditioanlParameteres() throws {
        
        let data =
        """
        { "access_token":"gg", "token_type":"Bearer", "expires_in": 1234, "refresh_token":"rtgg", "scope":"read write", "custom_param1": true, "custom_str": "zagreo", "my_int": 5 }
        """
        .data(using: .utf8)!
        
        let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let accessTokenResponse = try AccessTokenResponse(from: NetworkResponse(data: data, response: response))
        
        XCTAssertEqual(accessTokenResponse.accessToken, "gg")
        XCTAssertEqual(accessTokenResponse.tokenType, "Bearer")
        XCTAssertEqual(accessTokenResponse.expiresIn, 1234)
        XCTAssertEqual(accessTokenResponse.refreshToken, "rtgg")
        XCTAssertEqual(accessTokenResponse.scope?.rawValue, "read write")
        XCTAssertEqual(accessTokenResponse.additionalParameters["custom_param1"] as? Bool, true)
        XCTAssertEqual(accessTokenResponse.additionalParameters["custom_str"] as? String, "zagreo")
        XCTAssertEqual(accessTokenResponse.additionalParameters["my_int"] as? Int, 5)
    }
    
    func testMalformedJSON() throws {
     
        do {
            let data = "{}g".data(using: .utf8)!
            let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            _ = try AccessTokenResponse(from: NetworkResponse(data: data, response: response))
            XCTFail("An error should be thrown")
        }
        catch {}
    }
    
    func testInvalidParametersType() throws {
     
        do {
            let data = "[]".data(using: .utf8)!
            let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            _ = try AccessTokenResponse(from: NetworkResponse(data: data, response: response))
            XCTFail("An error should be thrown")
        }
        catch AccessTokenResponse.Error.invalidParametersType {}
    }
}
