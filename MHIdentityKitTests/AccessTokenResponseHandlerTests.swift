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
    
    func testError() {
        
        self.performExpectation { (e) in
            
            e.fulfilOnThrowing("err", { 
                
                _ = try AccessTokenResponseHandler().handle(data: nil, response: nil, error: "err")
            })
        }
        
        self.performExpectation { (e) in
            
            e.fulfilOnThrowing(MHIdentityKitError.Reason.unknownURLResponse, {
                
                _ = try AccessTokenResponseHandler().handle(data: nil, response: nil, error: nil)
            })
        }
        
        self.performExpectation { (e) in
            
            e.fulfilOnThrowing(MHIdentityKitError.Reason.unknownURLResponse, {
                
                _ = try AccessTokenResponseHandler().handle(data: nil, response: URLResponse(), error: nil)
            })
        }
        
        self.performExpectation { (e) in
            
            e.fulfilOnThrowing(MHIdentityKitError.Reason.unableToParseData, {
                
                let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 555, httpVersion: nil, headerFields: nil)
                _ = try AccessTokenResponseHandler().handle(data: nil, response: response, error: nil)
            })
        }
        
        self.performExpectation { (e) in
            
            e.fulfilOnThrowing(ErrorResponse(code: .invalidGrant), {
                
                let data = "{\"error\":\"invalid_grant\"}".data(using: .utf8)
                let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 555, httpVersion: nil, headerFields: nil)
                _ = try AccessTokenResponseHandler().handle(data: data, response: response, error: nil)
            })
        }
        
        self.performExpectation { (e) in
            
            e.fulfilOnThrowing(MHIdentityKitError.Reason.unknownHTTPResponse(code: 555), {
                
                let data = "{}".data(using: .utf8)
                let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 555, httpVersion: nil, headerFields: nil)
                _ = try AccessTokenResponseHandler().handle(data: data, response: response, error: nil)
            })
        }
        
        self.performExpectation { (e) in
            
            e.fulfilOnThrowing(MHIdentityKitError.Reason.unableToParseAccessToken, {
                
                let data = "{}".data(using: .utf8)
                let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 200, httpVersion: nil, headerFields: nil)
                _ = try AccessTokenResponseHandler().handle(data: data, response: response, error: nil)
            })
        }
        
        self.performExpectation { (e) in
            
            e.fulfilUnlessThrowing {
                
                let data = "{\"access_token\":\"gg\", \"token_type\":\"Bearer\", \"expires_in\": 1234, \"refresh_token\":\"rtgg\", \"scope\":\"read write\"}".data(using: .utf8)
                let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 200, httpVersion: nil, headerFields: nil)
                let accessTokenResponse = try AccessTokenResponseHandler().handle(data: data, response: response, error: nil)
                XCTAssertEqual(accessTokenResponse.accessToken, "gg")
                XCTAssertEqual(accessTokenResponse.tokenType, "Bearer")
                XCTAssertEqual(accessTokenResponse.expiresIn, 1234)
                XCTAssertEqual(accessTokenResponse.refreshToken, "rtgg")
                XCTAssertEqual(accessTokenResponse.scope?.rawValue, "read write")
            }
        }
    }
}
