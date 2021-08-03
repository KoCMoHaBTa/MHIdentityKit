//
//  AuthorizationCodeGrantFlowTests.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 28.03.18.
//  Copyright © 2018 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import MHIdentityKit

class AuthorizationCodeGrantFlowTests: XCTestCase {
    
    let authorizationEndpoint = URL(string: "http://foo.bar/auth")!
    let tokenEndpoint = URL(string: "http://foo.bar/token")!
    let clientID = "jarjar"
    let credentialsProvider = AnyCredentialsProvider(username: "tu", password: "tp")
    let scope: Scope = "read write"
    
    func testSuccessWithAllArguments() async throws {
        
        let redirectURI = URL(string: "ik://my.redirect.url/here/now")!
        let state: String? = "obi one"
        let clientAuthorizer: RequestAuthorizer? = HTTPBasicAuthorizer(clientID: "tcid", secret: "ts")
        
        var userAgentCallCount = 0
        let userAgent: UserAgent = AnyUserAgent { (request, redirectURI) in
            
            userAgentCallCount += 1
            XCTAssertEqual(request.url?.scheme, "http")
            XCTAssertEqual(request.url?.host, "foo.bar")
            XCTAssertEqual(request.url?.path, "/auth")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["response_type"], "code")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["client_id"], "jarjar")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["scope"], "read write")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["state"], "obi one")
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(redirectURI, URL(string: "ik://my.redirect.url/here/now"))
            
            //simulate successfull redirection
            return URLRequest(url: URL(string: "ik://my.redirect.url/here/now?code=abc&state=obi%20one")!)
        }
        finishHandler: { error in
            
            XCTAssertNil(error)
        }
        
        var networkClientCallCount = 0
        let networkClient: NetworkClient = AnyNetworkClient { request in
            
            networkClientCallCount += 1
            
            XCTAssertEqual(request.url, URL(string: "http://foo.bar/token"))
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic dGNpZDp0cw==")
            XCTAssertNotNil(request.httpBody)
            
            guard let parameters = request.httpBody?.urlDecodedParameters else {
                
                throw "Unable to decode body parameters"
            }
            
            XCTAssertEqual(parameters["grant_type"], "authorization_code")
            XCTAssertEqual(parameters["code"], "abc")
            XCTAssertEqual(parameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(parameters["client_id"], nil)
            
            let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234,\"refresh_token\":\"trt\",\"scope\":\"ts1 ts2\"}".data(using: .utf8)!
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)!
            
            return NetworkResponse(data: data, response: response)
        }
        
        let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(
            authorizationEndpoint: authorizationEndpoint,
            tokenEndpoint: tokenEndpoint,
            clientID: clientID,
            redirectURI: redirectURI,
            scope: scope,
            state: state,
            clientAuthorizer: clientAuthorizer,
            userAgent: userAgent,
            networkClient: networkClient
        )
        
        let response = try await flow.authenticate()
        
        XCTAssertEqual(userAgentCallCount, 1)
        XCTAssertEqual(networkClientCallCount, 1)
        
        XCTAssertEqual(response.accessToken, "tat")
        XCTAssertEqual(response.tokenType, "ttt")
        XCTAssertEqual(response.expiresIn, 1234)
        XCTAssertEqual(response.refreshToken, "trt")
        XCTAssertEqual(response.scope?.rawValue, "ts1 ts2")
    }
    
    func testSuccessWithoutClientAuthorizer() async throws {
        
        let redirectURI = URL(string: "ik://my.redirect.url/here/now")!
        let state: String? = "obi one"
        let clientAuthorizer: RequestAuthorizer? = nil
        
        var userAgentCallCount = 0
        let userAgent: UserAgent = AnyUserAgent { (request, redirectURI) in
            
            userAgentCallCount += 1
            
            XCTAssertEqual(request.url?.scheme, "http")
            XCTAssertEqual(request.url?.host, "foo.bar")
            XCTAssertEqual(request.url?.path, "/auth")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["response_type"], "code")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["client_id"], "jarjar")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["scope"], "read write")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["state"], "obi one")
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(redirectURI, URL(string: "ik://my.redirect.url/here/now"))
            
            //simulate successfull redirection
            return  URLRequest(url: URL(string: "ik://my.redirect.url/here/now?code=abc&state=obi%20one")!)
        }
        finishHandler: { error in
            
            XCTAssertNil(error)
        }
        
        var networkClientCallCount = 0
        let networkClient: NetworkClient = AnyNetworkClient { request in
            
            networkClientCallCount += 1
            
            XCTAssertEqual(request.url, URL(string: "http://foo.bar/token"))
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), nil)
            XCTAssertNotNil(request.httpBody)
            
            guard let parameters = request.httpBody?.urlDecodedParameters else {
                
                throw "Unable to decode body parameters"
            }
            
            XCTAssertEqual(parameters["grant_type"], "authorization_code")
            XCTAssertEqual(parameters["code"], "abc")
            XCTAssertEqual(parameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(parameters["client_id"], "jarjar")
            
            let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234,\"refresh_token\":\"trt\",\"scope\":\"ts1 ts2\"}".data(using: .utf8)!
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)!
            
            return NetworkResponse(data: data, response: response)
        }
        
        let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(
            authorizationEndpoint: authorizationEndpoint,
            tokenEndpoint: tokenEndpoint,
            clientID: clientID,
            redirectURI: redirectURI,
            scope: scope,
            state: state,
            clientAuthorizer: clientAuthorizer,
            userAgent: userAgent,
            networkClient: networkClient
        )
        
        let response = try await flow.authenticate()
        
        XCTAssertEqual(userAgentCallCount, 1)
        XCTAssertEqual(networkClientCallCount, 1)
        
        XCTAssertEqual(response.accessToken, "tat")
        XCTAssertEqual(response.tokenType, "ttt")
        XCTAssertEqual(response.expiresIn, 1234)
        XCTAssertEqual(response.refreshToken, "trt")
        XCTAssertEqual(response.scope?.rawValue, "ts1 ts2")
    }
    
    func testUserAgentCancel() async throws {
        
        let redirectURI = URL(string: "ik://my.redirect.url/here/now")!
        let state: String? = "obi one"
        let clientAuthorizer: RequestAuthorizer? = nil
        
        var userAgentCallCount = 0
        let userAgent: UserAgent = AnyUserAgent { (request, redirectURI) in
            
            userAgentCallCount += 1
            
            XCTAssertEqual(request.url?.scheme, "http")
            XCTAssertEqual(request.url?.host, "foo.bar")
            XCTAssertEqual(request.url?.path, "/auth")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["response_type"], "code")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["client_id"], "jarjar")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["scope"], "read write")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["state"], "obi one")
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(redirectURI, URL(string: "ik://my.redirect.url/here/now")!)
            
            //simulate cancel
            return nil
        }
        finishHandler: { error in
            XCTFail()
        }
        
        let networkClient: NetworkClient = AnyNetworkClient { request in
            
            XCTFail()
            throw "since user agent was cancelled, the token request should never be executed"
        }
        
        let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(
            authorizationEndpoint: authorizationEndpoint,
            tokenEndpoint: tokenEndpoint,
            clientID: clientID,
            redirectURI: redirectURI,
            scope: scope,
            state: state,
            clientAuthorizer: clientAuthorizer,
            userAgent: userAgent,
            networkClient: networkClient
        )
        
        do {
            _ = try await flow.authenticate()
        }
        catch AuthorizationCodeGrantFlow.Error.userAgentCancelled {}
        
        XCTAssertEqual(userAgentCallCount, 1)
    }
    
    func testSuccessWithoutOptionalArguments() async throws {
        
        let redirectURI = URL(string: "ik://my.redirect.url/here/now")!
        let state: String? = nil
        let clientAuthorizer: RequestAuthorizer? = nil
        
        var userAgentCallCount = 0
        let userAgent: UserAgent = AnyUserAgent { (request, redirectURI) in
            
            userAgentCallCount += 1
            
            XCTAssertEqual(request.url?.scheme, "http")
            XCTAssertEqual(request.url?.host, "foo.bar")
            XCTAssertEqual(request.url?.path, "/auth")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["response_type"], "code")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["client_id"], "jarjar")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["scope"], "read write")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["state"], nil)
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(redirectURI, URL(string: "ik://my.redirect.url/here/now")!)
            
            //simulate successfull redirection
            return URLRequest(url: URL(string: "ik://my.redirect.url/here/now?code=abc")!)
        }
        finishHandler: { error in
            XCTAssertNil(error)
        }
        
        var networkClientCallCount = 0
        let networkClient: NetworkClient = AnyNetworkClient { request in
            
            networkClientCallCount += 1
            
            XCTAssertEqual(request.url, URL(string: "http://foo.bar/token"))
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), nil)
            XCTAssertNotNil(request.httpBody)
            
            guard let parameters = request.httpBody?.urlDecodedParameters else {
                
                throw "Unable to decode body parameters"
            }
            
            XCTAssertEqual(parameters["grant_type"], "authorization_code")
            XCTAssertEqual(parameters["code"], "abc")
            XCTAssertEqual(parameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(parameters["client_id"], "jarjar")
            
            let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234,\"refresh_token\":\"trt\",\"scope\":\"ts1 ts2\"}".data(using: .utf8)!
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)!
            
            return NetworkResponse(data: data, response: response)
        }
        
        let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(
            authorizationEndpoint: authorizationEndpoint,
            tokenEndpoint: tokenEndpoint,
            clientID: clientID,
            redirectURI: redirectURI,
            scope: scope,
            state: state,
            clientAuthorizer: clientAuthorizer,
            userAgent: userAgent,
            networkClient: networkClient
        )
        
        let response = try await flow.authenticate()
        
        XCTAssertEqual(userAgentCallCount, 1)
        XCTAssertEqual(networkClientCallCount, 1)
        
        XCTAssertEqual(response.accessToken, "tat")
        XCTAssertEqual(response.tokenType, "ttt")
        XCTAssertEqual(response.expiresIn, 1234)
        XCTAssertEqual(response.refreshToken, "trt")
        XCTAssertEqual(response.scope?.rawValue, "ts1 ts2")
    }
    
    //when the state mismatch, the flow should complete with error
    func testErrorWithInvalidState() async throws {
        
        let redirectURI = URL(string: "ik://my.redirect.url/here/now")!
        let state: String? = "obi one"
        let clientAuthorizer: RequestAuthorizer? = HTTPBasicAuthorizer(clientID: "tcid", secret: "ts")
        
        var userAgentCallCount = 0
        let userAgent: UserAgent = AnyUserAgent { (request, redirectURI) in
            
            userAgentCallCount += 1
            
            XCTAssertEqual(request.url?.scheme, "http")
            XCTAssertEqual(request.url?.host, "foo.bar")
            XCTAssertEqual(request.url?.path, "/auth")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["response_type"], "code")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["client_id"], "jarjar")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["scope"], "read write")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["state"], "obi one")
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(redirectURI, URL(string: "ik://my.redirect.url/here/now"))
            
            //simulate fake redirection with wrong state
            return URLRequest(url: URL(string: "ik://my.redirect.url/here/now?code=abc&state=fake")!)
        }
        
        let networkClient: NetworkClient = AnyNetworkClient { request in
            
            XCTFail()
            //since state is wrong, the token request should never be executed
            throw "since state is wrong, the token request should never be executed"
        }
        
        let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(
            authorizationEndpoint: authorizationEndpoint,
            tokenEndpoint: tokenEndpoint,
            clientID: clientID,
            redirectURI: redirectURI,
            scope: scope,
            state: state,
            clientAuthorizer: clientAuthorizer,
            userAgent: userAgent,
            networkClient: networkClient
        )
        
        do {
            _ = try await flow.authenticate()
        }
        catch AuthorizationCodeGrantFlow.Error.athorizationResponseStateMismatch {}
        
        XCTAssertEqual(userAgentCallCount, 1)
    }
    
    //When the redirect uri mismatch, the flow should throw an error
    func testErrorWithRedirectURIMismatch() async throws {
        
        let redirectURI = URL(string: "ik://my.redirect.url/here/now")!
        let state: String? = "obi one"
        let clientAuthorizer: RequestAuthorizer? = HTTPBasicAuthorizer(clientID: "tcid", secret: "ts")
        
        var userAgentCallCount = 0
        let userAgent: UserAgent = AnyUserAgent { (request, redirectURI) in
            
            userAgentCallCount += 1
            
            XCTAssertEqual(request.url?.scheme, "http")
            XCTAssertEqual(request.url?.host, "foo.bar")
            XCTAssertEqual(request.url?.path, "/auth")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["response_type"], "code")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["client_id"], "jarjar")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["scope"], "read write")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["state"], "obi one")
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(redirectURI, URL(string: "ik://my.redirect.url/here/now"))
            
            //simulate fake redirection with wrong url
            return URLRequest(url: URL(string: "ik://my.scam.url/here/now?code=abc&state=obi%20one")!)
        }
        finishHandler: { error in
            
            XCTAssertNotNil(error)
        }
        
        var networkClientCallCount = 0
        let networkClient: NetworkClient = AnyNetworkClient { request in
            
            networkClientCallCount += 1
            throw "this should not be called"
        }
        
        let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(
            authorizationEndpoint: authorizationEndpoint,
            tokenEndpoint: tokenEndpoint,
            clientID: clientID,
            redirectURI: redirectURI,
            scope: scope,
            state: state,
            clientAuthorizer: clientAuthorizer,
            userAgent: userAgent,
            networkClient: networkClient
        )
        
        do {
            _ = try await flow.authenticate()
        }
        catch AuthorizationCodeGrantFlow.Error.redirectURIMismatch {}
        
        XCTAssertEqual(userAgentCallCount, 1)
        XCTAssertEqual(networkClientCallCount, 0)
    }
    
    //when the redirect rquest contains an error - it should be thrown
    func testErrorFromUserAgent() async throws {
        
        let redirectURI = URL(string: "ik://my.redirect.url/here/now")!
        let state: String? = "obi one"
        let clientAuthorizer: RequestAuthorizer? = HTTPBasicAuthorizer(clientID: "tcid", secret: "ts")
        
        var userAgentCallCount = 0
        let userAgent: UserAgent = AnyUserAgent { (request, redirectURI) in
            
            userAgentCallCount += 1
            
            XCTAssertEqual(request.url?.scheme, "http")
            XCTAssertEqual(request.url?.host, "foo.bar")
            XCTAssertEqual(request.url?.path, "/auth")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["response_type"], "code")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["client_id"], "jarjar")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["scope"], "read write")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["state"], "obi one")
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(redirectURI, URL(string: "ik://my.redirect.url/here/now"))
            
            //simulate fake redirection with error
            return URLRequest(url: URL(string: "ik://my.redirect.url/here/now?error=access_denied")!)
        }
        finishHandler: { error in
            XCTAssertNil(error)
        }
        
        var networkClientCallCount = 0
        let networkClient: NetworkClient = AnyNetworkClient { request in
            
            networkClientCallCount += 1
            throw "this should not be called"
        }
        
        let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(
            authorizationEndpoint: authorizationEndpoint,
            tokenEndpoint: tokenEndpoint,
            clientID: clientID,
            redirectURI: redirectURI,
            scope: scope,
            state: state,
            clientAuthorizer: clientAuthorizer,
            userAgent: userAgent,
            networkClient: networkClient
        )
        
        do {
            _ = try await flow.authenticate()
        }
        catch let error as OAuth2Error where error.code == .accessDenied {}
        
        XCTAssertEqual(userAgentCallCount, 1)
        XCTAssertEqual(networkClientCallCount, 0)
    }
    
    func testErrorFromNetworkClient() async throws {
        
        let redirectURI = URL(string: "ik://my.redirect.url/here/now")!
        let state: String? = "obi one"
        let clientAuthorizer: RequestAuthorizer? = HTTPBasicAuthorizer(clientID: "tcid", secret: "ts")
        
        var userAgentCallCount = 0
        let userAgent: UserAgent = AnyUserAgent { (request, redirectURI) in
            
            userAgentCallCount += 1
            
            XCTAssertEqual(request.url?.scheme, "http")
            XCTAssertEqual(request.url?.host, "foo.bar")
            XCTAssertEqual(request.url?.path, "/auth")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["response_type"], "code")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["client_id"], "jarjar")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["scope"], "read write")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["state"], "obi one")
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(redirectURI, URL(string: "ik://my.redirect.url/here/now"))
            
            //simulate successfull redirection
            return URLRequest(url: URL(string: "ik://my.redirect.url/here/now?code=abc&state=obi%20one")!)
        }
        finishHandler: { error in
            XCTAssertNil(error)
        }
        
        var networkClientCallCount = 0
        let networkClient: NetworkClient = AnyNetworkClient { request in
            
            networkClientCallCount += 1
            
            XCTAssertEqual(request.url, URL(string: "http://foo.bar/token"))
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic dGNpZDp0cw==")
            XCTAssertNotNil(request.httpBody)
            
            guard let parameters = request.httpBody?.urlDecodedParameters else {
                
                throw "Unable to decode body parameters"
            }
            
            XCTAssertEqual(parameters["grant_type"], "authorization_code")
            XCTAssertEqual(parameters["code"], "abc")
            XCTAssertEqual(parameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(parameters["client_id"], nil)
            
            let data = "{\"error\":\"invalid_scope\"}".data(using: .utf8)!
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 400, httpVersion: nil, headerFields: nil)!
            
            return NetworkResponse(data: data, response: response)
        }
        
        let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(
            authorizationEndpoint: authorizationEndpoint,
            tokenEndpoint: tokenEndpoint,
            clientID: clientID,
            redirectURI: redirectURI,
            scope: scope,
            state: state,
            clientAuthorizer: clientAuthorizer,
            userAgent: userAgent,
            networkClient: networkClient
        )
        
        
        do {
            _ = try await flow.authenticate()
        }
        catch let error as OAuth2Error where error.code == .invalidScope {}
        
        XCTAssertEqual(userAgentCallCount, 1)
        XCTAssertEqual(networkClientCallCount, 1)
    }
    
    func testAdditionalParameters() async throws {
        
        let redirectURI = URL(string: "ik://my.redirect.url/here/now")!
        let state: String? = "obi one"
        let clientAuthorizer: RequestAuthorizer? = HTTPBasicAuthorizer(clientID: "tcid", secret: "ts")
        
        var userAgentCallCount = 0
        let userAgent: UserAgent = AnyUserAgent { (request, redirectURI) in
            
            userAgentCallCount += 1
            
            XCTAssertEqual(request.url?.scheme, "http")
            XCTAssertEqual(request.url?.host, "foo.bar")
            XCTAssertEqual(request.url?.path, "/auth")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["response_type"], "code")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["client_id"], "tampered jarjar")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["scope"], "read write")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["state"], "obi one")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["additional_parameter_1"], "ap1")
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(redirectURI, URL(string: "ik://my.redirect.url/here/now"))
            
            //simulate successfull redirection
            return URLRequest(url: URL(string: "ik://my.redirect.url/here/now?code=abc&state=obi%20one")!)
        }
        finishHandler: { error in
            XCTAssertNil(error)
        }
        
        var networkClientCallCount = 0
        let networkClient: NetworkClient = AnyNetworkClient { request in
            
            networkClientCallCount += 1
            
            XCTAssertEqual(request.url, URL(string: "http://foo.bar/token"))
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic dGNpZDp0cw==")
            XCTAssertNotNil(request.httpBody)
            
            guard let parameters = request.httpBody?.urlDecodedParameters else {
                
                throw "Unable to decode body parameters"
            }
            
            XCTAssertEqual(parameters["grant_type"], "authorization_code")
            XCTAssertEqual(parameters["code"], "tampered abc")
            XCTAssertEqual(parameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(parameters["client_id"], nil)
            XCTAssertEqual(parameters["additional_parameter_2"], "ap2")
            
            let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234,\"refresh_token\":\"trt\",\"scope\":\"ts1 ts2\"}".data(using: .utf8)!
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)!
            
            return NetworkResponse(data: data, response: response)
        }
        
        let flow = AuthorizationCodeGrantFlow(
            authorizationEndpoint: authorizationEndpoint,
            tokenEndpoint: tokenEndpoint,
            clientID: clientID,
            redirectURI: redirectURI,
            scope: scope,
            state: state,
            clientAuthorizer: clientAuthorizer,
            userAgent: userAgent,
            networkClient: networkClient
        )
        
        //set additional  parameters and override some of existing ones
        flow.additionalAuthorizationRequestParameters = ["additional_parameter_1": "ap1", "client_id": "tampered jarjar"]
        flow.additionalAccessTokenRequestParameters = ["additional_parameter_2": "ap2", "code": "tampered abc"]
        
        let response = try await flow.authenticate()
        
        XCTAssertEqual(userAgentCallCount, 1)
        XCTAssertEqual(networkClientCallCount, 1)
        
        XCTAssertEqual(response.accessToken, "tat")
        XCTAssertEqual(response.tokenType, "ttt")
        XCTAssertEqual(response.expiresIn, 1234)
        XCTAssertEqual(response.refreshToken, "trt")
        XCTAssertEqual(response.scope?.rawValue, "ts1 ts2")
        
    }
}





