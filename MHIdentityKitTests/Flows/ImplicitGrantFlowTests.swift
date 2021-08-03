//
//  ImplicitGrantFlowTests.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 1.07.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import MHIdentityKit

class ImplicitGrantFlowTests: XCTestCase {
    
    let authorizationEndpoint = URL(string: "http://foo.bar/auth")!
    let clientID = "jarjar"
    let credentialsProvider = AnyCredentialsProvider(username: "tu", password: "tp")
    let scope: Scope = "read write"
    
    func testAccessTokenResponseBuilding() throws {
        
        let url = URL(string: "http://example.com/cb#access_token=2YotnFZFEjr1zCsicMWpAA&state=xyz&token_type=example&expires_in=3600&scope=sc1%20sc2")!
        let parameters = url.fragment!.urlDecodedParameters
        let response = try XCTUnwrap(AccessTokenResponse(parameters: parameters))
        
        XCTAssertEqual(response.accessToken, "2YotnFZFEjr1zCsicMWpAA")
        XCTAssertEqual(response.tokenType, "example")
        XCTAssertEqual(response.expiresIn, 3600)
        XCTAssertEqual(response.scope, "sc1 sc2")
        XCTAssertEqual(response.additionalParameters["state"] as? String, "xyz")
    }
    
    func testSuccessWithAllArguments() async throws {
        
        let redirectURI = URL(string: "ik://my.redirect.url/here/now")!
        let state: String? = "obi one"
        
        var userAgentCallCount = 0
        let userAgent: UserAgent = AnyUserAgent { (request, redirectURI) in
            
            userAgentCallCount += 1
            XCTAssertEqual(request.url?.scheme, "http")
            XCTAssertEqual(request.url?.host, "foo.bar")
            XCTAssertEqual(request.url?.path, "/auth")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["response_type"], "token")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["client_id"], "jarjar")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["scope"], "read write")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["state"], "obi one")
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(redirectURI, URL(string: "ik://my.redirect.url/here/now"))
            
            //simulate successfull redirection
            return URLRequest(url: URL(string: "ik://my.redirect.url/here/now#access_token=tat&token_type=ttt&expires_in=1234&scope=ts1%20ts2&state=obi%20one")!)
        }
        finishHandler: { error in
            
            XCTAssertNil(error)
        }
        
        let flow: AuthorizationGrantFlow = ImplicitGrantFlow(
            authorizationEndpoint: authorizationEndpoint,
            clientID: clientID,
            redirectURI: redirectURI,
            scope: scope,
            state: state,
            userAgent: userAgent
        )
        
        let response = try await flow.authenticate()
        
        XCTAssertEqual(userAgentCallCount, 1)
        
        XCTAssertEqual(response.accessToken, "tat")
        XCTAssertEqual(response.tokenType, "ttt")
        XCTAssertEqual(response.expiresIn, 1234)
        XCTAssertNil(response.refreshToken)
        XCTAssertEqual(response.scope?.rawValue, "ts1 ts2")
    }
    
    func testUserAgentCancel() async throws {
        
        let redirectURI = URL(string: "ik://my.redirect.url/here/now")!
        let state: String? = "obi one"
        
        var userAgentCallCount = 0
        let userAgent: UserAgent = AnyUserAgent { (request, redirectURI) in
            
            userAgentCallCount += 1
            XCTAssertEqual(request.url?.scheme, "http")
            XCTAssertEqual(request.url?.host, "foo.bar")
            XCTAssertEqual(request.url?.path, "/auth")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["response_type"], "token")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["client_id"], "jarjar")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["scope"], "read write")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["state"], "obi one")
            XCTAssertEqual(request.httpMethod, "GET")
            
            //simulate cancel
            return nil
        }
        finishHandler: { error in
            XCTFail()
        }
        
        let flow: AuthorizationGrantFlow = ImplicitGrantFlow(
            authorizationEndpoint: authorizationEndpoint,
            clientID: clientID,
            redirectURI: redirectURI,
            scope: scope,
            state: state,
            userAgent: userAgent
        )
        
        do {
            _ = try await flow.authenticate()
        }
        catch ImplicitGrantFlow.Error.userAgentCancelled {}
    }
    
    func testSuccessWithoutOptionalArguments() async throws {
        
        let redirectURI = URL(string: "ik://my.redirect.url/here/now")!
        let state: String? = nil
        
        var userAgentCallCount = 0
        let userAgent: UserAgent = AnyUserAgent { (request, redirectURI) in
            
            userAgentCallCount += 1
            XCTAssertEqual(request.url?.scheme, "http")
            XCTAssertEqual(request.url?.host, "foo.bar")
            XCTAssertEqual(request.url?.path, "/auth")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["response_type"], "token")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["client_id"], "jarjar")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["scope"], "read write")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["state"], nil)
            XCTAssertEqual(request.httpMethod, "GET")
            
            //simulate successfull redirection
            return URLRequest(url: URL(string: "ik://my.redirect.url/here/now#access_token=tat&token_type=ttt&expires_in=1234&scope=ts1%20ts2")!)
        }
        finishHandler: { error in
            
            XCTAssertNil(error)
        }
        
        let flow: AuthorizationGrantFlow = ImplicitGrantFlow(
            authorizationEndpoint: authorizationEndpoint,
            clientID: clientID,
            redirectURI: redirectURI,
            scope: scope,
            state: state,
            userAgent: userAgent
        )
        
        let response = try await flow.authenticate()
        
        XCTAssertEqual(userAgentCallCount, 1)
        
        XCTAssertEqual(response.accessToken, "tat")
        XCTAssertEqual(response.tokenType, "ttt")
        XCTAssertEqual(response.expiresIn, 1234)
        XCTAssertNil(response.refreshToken)
        XCTAssertEqual(response.scope?.rawValue, "ts1 ts2")
    }
    
    //when the state mismatch, the flow should complete with error
    func testErrorWithInvalidState() async throws  {
        
        let redirectURI = URL(string: "ik://my.redirect.url/here/now")!
        let state: String? = "obi one"
        
        var userAgentCallCount = 0
        let userAgent: UserAgent = AnyUserAgent { (request, redirectURI) in
            
            userAgentCallCount += 1
            XCTAssertEqual(request.url?.scheme, "http")
            XCTAssertEqual(request.url?.host, "foo.bar")
            XCTAssertEqual(request.url?.path, "/auth")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["response_type"], "token")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["client_id"], "jarjar")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["scope"], "read write")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["state"], "obi one")
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(redirectURI, URL(string: "ik://my.redirect.url/here/now"))
            
            //simulate fake redirection with wrong state
            return URLRequest(url: URL(string: "ik://my.redirect.url/here/now#access_token=tat&token_type=ttt&expires_in=1234&scope=ts1%20ts2&state=fake")!)
        }
        finishHandler: { error in
            
            XCTAssertNil(error)
        }
        
        let flow: AuthorizationGrantFlow = ImplicitGrantFlow(
            authorizationEndpoint: authorizationEndpoint,
            clientID: clientID,
            redirectURI: redirectURI,
            scope: scope,
            state: state,
            userAgent: userAgent
        )
        
        do {
            _ = try await flow.authenticate()
        }
        catch ImplicitGrantFlow.Error.accessTokenResponseStateMismatch {}
    }
    
    //When the redirect uri mismatch, the flow should throw error
    func testErrorWithRedirectURIMismatch() async throws {
        
        let redirectURI = URL(string: "ik://my.redirect.url/here/now")!
        let state: String? = "obi one"
        
        var userAgentCallCount = 0
        let userAgent: UserAgent = AnyUserAgent { (request, redirectURI) in
            
            userAgentCallCount += 1
            XCTAssertEqual(request.url?.scheme, "http")
            XCTAssertEqual(request.url?.host, "foo.bar")
            XCTAssertEqual(request.url?.path, "/auth")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["response_type"], "token")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["client_id"], "jarjar")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["scope"], "read write")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["state"], "obi one")
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(redirectURI, URL(string: "ik://my.redirect.url/here/now"))
            
            //simulate fake redirection with wrong url
            return URLRequest(url: URL(string: "ik://my.scam.url/here/now#access_token=tat&token_type=ttt&expires_in=1234&scope=ts1%20ts2&state=obi%20one")!)
        }
        finishHandler: { error in
            
            XCTAssertNotNil(error)
        }
        
        let flow: AuthorizationGrantFlow = ImplicitGrantFlow(
            authorizationEndpoint: authorizationEndpoint,
            clientID: clientID,
            redirectURI: redirectURI,
            scope: scope,
            state: state,
            userAgent: userAgent
        )
        
        do {
            _ = try await flow.authenticate()
        }
        catch ImplicitGrantFlow.Error.redirectURIMismatch {}
    }
    
    //when the state mismatch, the flow should complete with error
    func testErrorFromUserAgent() async throws {
        
        let redirectURI = URL(string: "ik://my.redirect.url/here/now")!
        let state: String? = "obi one"
        
        var userAgentCallCount = 0
        let userAgent: UserAgent = AnyUserAgent { (request, redirectURI) in
            
            userAgentCallCount += 1
            XCTAssertEqual(request.url?.scheme, "http")
            XCTAssertEqual(request.url?.host, "foo.bar")
            XCTAssertEqual(request.url?.path, "/auth")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["response_type"], "token")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["client_id"], "jarjar")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["scope"], "read write")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["state"], "obi one")
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(redirectURI, URL(string: "ik://my.redirect.url/here/now"))
            
            
            //simulate redirect with error
            return URLRequest(url: URL(string: "ik://my.redirect.url/here/now#error=access_denied")!)
        }
        
        let flow: AuthorizationGrantFlow = ImplicitGrantFlow(
            authorizationEndpoint: authorizationEndpoint,
            clientID: clientID,
            redirectURI: redirectURI,
            scope: scope,
            state: state,
            userAgent: userAgent
        )
        
        do {
            _ = try await flow.authenticate()
        }
        catch let error as OAuth2Error where error.code == .accessDenied {}
    }
    
    func testAdditionalParameters() async throws {
        
        let redirectURI = URL(string: "ik://my.redirect.url/here/now")!
        let state: String? = "obi one"
        
        var userAgentCallCount = 0
        let userAgent: UserAgent = AnyUserAgent { (request, redirectURI) in
            
            userAgentCallCount += 1
            XCTAssertEqual(request.url?.scheme, "http")
            XCTAssertEqual(request.url?.host, "foo.bar")
            XCTAssertEqual(request.url?.path, "/auth")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["response_type"], "token")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["client_id"], "tampered jarjar")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["scope"], "read write")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["state"], "obi one")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["additional_parameter_1"], "ap1")
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(redirectURI, URL(string: "ik://my.redirect.url/here/now"))
            
            //simulate successfull redirection
            return URLRequest(url: URL(string: "ik://my.redirect.url/here/now#access_token=tat&token_type=ttt&expires_in=1234&scope=ts1%20ts2&state=obi%20one")!)
        }
        
        let flow = ImplicitGrantFlow(authorizationEndpoint: authorizationEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, userAgent: userAgent)
        
        //set additional  parameters and override some of existing ones
        flow.additionalAuthorizationRequestParameters = ["additional_parameter_1": "ap1", "client_id": "tampered jarjar"]
        
        let response = try await flow.authenticate()
        
        XCTAssertEqual(response.accessToken, "tat")
        XCTAssertEqual(response.tokenType, "ttt")
        XCTAssertEqual(response.expiresIn, 1234)
        XCTAssertNil(response.refreshToken)
        XCTAssertEqual(response.scope?.rawValue, "ts1 ts2")
    }
}
