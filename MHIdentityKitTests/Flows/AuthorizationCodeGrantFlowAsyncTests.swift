//
//  AuthorizationCodeGrantFlowAsyncTests.swift
//  MHIdentityKit
//
//  Created by Lyubomir Yordanov on 8/5/22.
//  Copyright © 2022 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import MHIdentityKit

@available(iOS 13, *)
class AuthorizationCodeGrantFlowAsyncTests: XCTestCase {
    
    let authorizationEndpoint = URL(string: "http://foo.bar/auth")!
    let tokenEndpoint = URL(string: "http://foo.bar/token")!
    let clientID = "jarjar"
    let credentialsProvider = AnyCredentialsProvider(username: "tu", password: "tp")
    let scope: Scope = "read write"
    
    func testSuccessWithAllArgumentsAsync() async {
        
        let redirectURI: URL? = URL(string: "ik://my.redirect.url/here/now")
        let state: AnyHashable? = "obi one"
        let clientAuthorizer: RequestAuthorizer? = HTTPBasicAuthorizer(clientID: "tcid", secret: "ts")
        
        let userAgent: UserAgent = TestUserAgent(handler: { (request, redirectURI, redirectionHandler) in
            
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
            
            do {
                
                //simulate successfull redirection
                let redirectRequest = URLRequest(url: URL(string: "ik://my.redirect.url/here/now?code=abc&state=obi%20one")!)
                let handled = try redirectionHandler(redirectRequest)
                XCTAssertTrue(handled)
            }
            catch {
                
                XCTFail()
            }
            
        })
        
        let networkClient: NetworkClient = TestNetworkClient(handler: { (request, completion) in
            
            XCTAssertEqual(request.url, URL(string: "http://foo.bar/token"))
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic dGNpZDp0cw==")
            XCTAssertNotNil(request.httpBody)
            
            guard
                let parameters = request.httpBody?.urlDecodedParameters
            else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(parameters["grant_type"], "authorization_code")
            XCTAssertEqual(parameters["code"], "abc")
            XCTAssertEqual(parameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(parameters["client_id"], nil)
            
            let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234,\"refresh_token\":\"trt\",\"scope\":\"ts1 ts2\"}".data(using: .utf8)
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)
            
            completion(NetworkResponse(data: data, response: response, error: nil))
        })
        
        let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
        
        let response = try? await flow.authenticateAsync()
        
        XCTAssertNotNil(response)
        
        XCTAssertEqual(response?.accessToken, "tat")
        XCTAssertEqual(response?.tokenType, "ttt")
        XCTAssertEqual(response?.expiresIn, 1234)
        XCTAssertEqual(response?.refreshToken, "trt")
        XCTAssertEqual(response?.scope?.value, "ts1 ts2")
    }
    
    func testSuccessWithoutClientAuthorizerAsync() async {
        
        let redirectURI: URL? = URL(string: "ik://my.redirect.url/here/now")
        let state: AnyHashable? = "obi one"
        let clientAuthorizer: RequestAuthorizer? = nil
        
        let userAgent: UserAgent = TestUserAgent(handler: { (request, redirectURI, redirectionHandler) in
            
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
            
            do {
                
                //simulate successfull redirection
                let redirectRequest = URLRequest(url: URL(string: "ik://my.redirect.url/here/now?code=abc&state=obi%20one")!)
                let handled = try redirectionHandler(redirectRequest)
                XCTAssertTrue(handled)
            }
            catch {
                
                XCTFail()
            }
        })
        
        let networkClient: NetworkClient = TestNetworkClient(handler: { (request, completion) in
            
            XCTAssertEqual(request.url, URL(string: "http://foo.bar/token"))
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), nil)
            XCTAssertNotNil(request.httpBody)
            
            guard
                let parameters = request.httpBody?.urlDecodedParameters
            else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(parameters["grant_type"], "authorization_code")
            XCTAssertEqual(parameters["code"], "abc")
            XCTAssertEqual(parameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(parameters["client_id"], "jarjar")
            
            let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234,\"refresh_token\":\"trt\",\"scope\":\"ts1 ts2\"}".data(using: .utf8)
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)
            
            completion(NetworkResponse(data: data, response: response, error: nil))
        })
        
        let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
        
        let response = try? await flow.authenticateAsync()
        
        XCTAssertNotNil(response)
        
        XCTAssertEqual(response?.accessToken, "tat")
        XCTAssertEqual(response?.tokenType, "ttt")
        XCTAssertEqual(response?.expiresIn, 1234)
        XCTAssertEqual(response?.refreshToken, "trt")
        XCTAssertEqual(response?.scope?.value, "ts1 ts2")
    }
    
    func testSuccessWithoutRedirectURIAsync() async {
        
        let redirectURI: URL? = nil
        let state: AnyHashable? = "obi one"
        let clientAuthorizer: RequestAuthorizer? = nil
        
        let userAgent: UserAgent = TestUserAgent(handler: { (request, redirectURI, redirectionHandler) in
            
            XCTAssertEqual(request.url?.scheme, "http")
            XCTAssertEqual(request.url?.host, "foo.bar")
            XCTAssertEqual(request.url?.path, "/auth")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["response_type"], "code")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["client_id"], "jarjar")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["redirect_uri"], nil)
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["scope"], "read write")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["state"], "obi one")
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(redirectURI, nil)
            
            do {
                
                //simulate successfull redirection
                let redirectRequest = URLRequest(url: URL(string: "ik://my.redirect.url/here/now?code=abc&state=obi%20one")!)
                let handled = try redirectionHandler(redirectRequest)
                XCTAssertTrue(handled)
            }
            catch {
                
                XCTFail()
            }
        })
        
        let networkClient: NetworkClient = TestNetworkClient(handler: { (request, completion) in
            
            XCTAssertEqual(request.url, URL(string: "http://foo.bar/token"))
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), nil)
            XCTAssertNotNil(request.httpBody)
            
            guard
                let parameters = request.httpBody?.urlDecodedParameters
            else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(parameters["grant_type"], "authorization_code")
            XCTAssertEqual(parameters["code"], "abc")
            XCTAssertEqual(parameters["redirect_uri"], nil)
            XCTAssertEqual(parameters["client_id"], "jarjar")
            
            let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234,\"refresh_token\":\"trt\",\"scope\":\"ts1 ts2\"}".data(using: .utf8)
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)
            
            completion(NetworkResponse(data: data, response: response, error: nil))
        })
        
        let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
        
        let response = try? await flow.authenticateAsync()
        
        XCTAssertNotNil(response)
        
        XCTAssertEqual(response?.accessToken, "tat")
        XCTAssertEqual(response?.tokenType, "ttt")
        XCTAssertEqual(response?.expiresIn, 1234)
        XCTAssertEqual(response?.refreshToken, "trt")
        XCTAssertEqual(response?.scope?.value, "ts1 ts2")
    }
    
    func testSuccessWithoutOptionalArgumentsAsync() async {
        
        let redirectURI: URL? = nil
        let state: AnyHashable? = nil
        let clientAuthorizer: RequestAuthorizer? = nil
        
        let userAgent: UserAgent = TestUserAgent(handler: { (request, redirectURI, redirectionHandler) in
            
            XCTAssertEqual(request.url?.scheme, "http")
            XCTAssertEqual(request.url?.host, "foo.bar")
            XCTAssertEqual(request.url?.path, "/auth")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["response_type"], "code")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["client_id"], "jarjar")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["redirect_uri"], nil)
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["scope"], "read write")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["state"], nil)
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(redirectURI, nil)
            
            do {
                
                //simulate successfull redirection
                let redirectRequest = URLRequest(url: URL(string: "ik://my.redirect.url/here/now?code=abc")!)
                let handled = try redirectionHandler(redirectRequest)
                XCTAssertTrue(handled)
            }
            catch {
                
                XCTFail()
            }
        })
        
        let networkClient: NetworkClient = TestNetworkClient(handler: { (request, completion) in
            
            XCTAssertEqual(request.url, URL(string: "http://foo.bar/token"))
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), nil)
            XCTAssertNotNil(request.httpBody)
            
            guard
                let parameters = request.httpBody?.urlDecodedParameters
            else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(parameters["grant_type"], "authorization_code")
            XCTAssertEqual(parameters["code"], "abc")
            XCTAssertEqual(parameters["redirect_uri"], nil)
            XCTAssertEqual(parameters["client_id"], "jarjar")
            
            let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234,\"refresh_token\":\"trt\",\"scope\":\"ts1 ts2\"}".data(using: .utf8)
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)
            
            completion(NetworkResponse(data: data, response: response, error: nil))
        })
        
        let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
        
        let response = try? await flow.authenticateAsync()
        
        XCTAssertNotNil(response)
        
        XCTAssertEqual(response?.accessToken, "tat")
        XCTAssertEqual(response?.tokenType, "ttt")
        XCTAssertEqual(response?.expiresIn, 1234)
        XCTAssertEqual(response?.refreshToken, "trt")
        XCTAssertEqual(response?.scope?.value, "ts1 ts2")
    }
    
    //when the state mismatch, the flow should complete with error
    func testErrorWithInvalidStateAsync() async {
        
        let redirectURI: URL? = URL(string: "ik://my.redirect.url/here/now")
        let state: AnyHashable? = "obi one"
        let clientAuthorizer: RequestAuthorizer? = HTTPBasicAuthorizer(clientID: "tcid", secret: "ts")
        
        let userAgent: UserAgent = TestUserAgent(handler: { (request, redirectURI, redirectionHandler) in
            
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
            
            do {
                
                //simulate fake redirection with wrong state
                let redirectRequest = URLRequest(url: URL(string: "ik://my.redirect.url/here/now?code=abc&state=fake")!)
                _ = try redirectionHandler(redirectRequest)
                XCTFail()
            }
            catch {
                
            }
        })
        
        let networkClient: NetworkClient = TestNetworkClient(handler: { (request, completion) in
            
            //since state is wrong, the token request should never be executed
            XCTFail()
        })
        
        let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
        
        let response = try? await flow.authenticateAsync()
        
        XCTAssertNil(response)
    }
    
    //When the redirect uri mismatch, the flow should wait for matching uri
    func testErrorWithRedirectURIMismatchAsync() {
        
        let redirectURI: URL? = URL(string: "ik://my.redirect.url/here/now")
        let state: AnyHashable? = "obi one"
        let clientAuthorizer: RequestAuthorizer? = HTTPBasicAuthorizer(clientID: "tcid", secret: "ts")
        
        let userAgent: UserAgent = TestUserAgent(handler: { (request, redirectURI, redirectionHandler) in
            
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
            
            do {
                
                //simulate fake redirection with wrong url
                let redirectRequest = URLRequest(url: URL(string: "ik://my.scam.url/here/now?code=abc&state=obi%20one")!)
                let handled = try redirectionHandler(redirectRequest)
                XCTAssertFalse(handled)
            }
            catch {
                
                XCTFail()
            }
        })
        
        let networkClient: NetworkClient = TestNetworkClient(handler: { (request, completion) in
            
            XCTFail()
        })
        
        let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
        
        Task.init {
            
            _ = try? await flow.authenticateAsync()
            XCTFail()
        }
    }
    
    //When the redirect uri mismatch, the flow should wait for matching uri
    func testSuccessWithMultipleRedirectionsAsync() async {
        
        let redirectURI: URL? = URL(string: "ik://my.redirect.url/here/now")
        let state: AnyHashable? = "obi one"
        let clientAuthorizer: RequestAuthorizer? = HTTPBasicAuthorizer(clientID: "tcid", secret: "ts")
        
        let userAgent: UserAgent = TestUserAgent(handler: { (request, redirectURI, redirectionHandler) in
            
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
            
            do {
                
                //simulate mismatch redirection
                let handled = try redirectionHandler(URLRequest(url: URL(string: "ik://my.fake1.url/here/now?code=abc&state=obi%20one")!))
                XCTAssertFalse(handled)
                
                //simulate mismatch redirection
                let handled1 = try redirectionHandler(URLRequest(url: URL(string: "ik://fake.redirect.url/here/now?code=abc&state=obi%20one")!))
                XCTAssertFalse(handled1)
                
                //simulate mismatch redirection
                let handled2 = try redirectionHandler(URLRequest(url: URL(string: "ik://my.redirect.fake/here/now?code=abc&state=obi%20one")!))
                XCTAssertFalse(handled2)
                
                //simulate mismatch redirection
                let handled3 = try redirectionHandler(URLRequest(url: URL(string: "ik://my.redirect.url/here/fake?code=abc&state=obi%20one")!))
                XCTAssertFalse(handled3)
                
                //simulate mismatch redirection
                let handled4 = try redirectionHandler(URLRequest(url: URL(string: "ik://my.redirect.url/here/now")!))
                XCTAssertFalse(handled4)
                
                //simulate successfull redirection
                let handled5 = try redirectionHandler(URLRequest(url: URL(string: "ik://my.redirect.url/here/now?code=abc&state=obi%20one")!))
                XCTAssertTrue(handled5)
            }
            catch {
                
                XCTFail()
            }
        })
        
        let networkClient: NetworkClient = TestNetworkClient(handler: { (request, completion) in
            
            XCTAssertEqual(request.url, URL(string: "http://foo.bar/token"))
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic dGNpZDp0cw==")
            XCTAssertNotNil(request.httpBody)
            
            guard
                let parameters = request.httpBody?.urlDecodedParameters
            else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(parameters["grant_type"], "authorization_code")
            XCTAssertEqual(parameters["code"], "abc")
            XCTAssertEqual(parameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(parameters["client_id"], nil)
            
            let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234,\"refresh_token\":\"trt\",\"scope\":\"ts1 ts2\"}".data(using: .utf8)
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)
            
            completion(NetworkResponse(data: data, response: response, error: nil))
        })
        
        let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
        
        let response = try? await flow.authenticateAsync()
        
        XCTAssertNotNil(response)
        
        XCTAssertEqual(response?.accessToken, "tat")
        XCTAssertEqual(response?.tokenType, "ttt")
        XCTAssertEqual(response?.expiresIn, 1234)
        XCTAssertEqual(response?.refreshToken, "trt")
        XCTAssertEqual(response?.scope?.value, "ts1 ts2")
    }
    
    //when the state mismatch, the flow should complete with error
    func testErrorFromUserAgentAsync() async {
        
        let redirectURI: URL? = URL(string: "ik://my.redirect.url/here/now")
        let state: AnyHashable? = "obi one"
        let clientAuthorizer: RequestAuthorizer? = HTTPBasicAuthorizer(clientID: "tcid", secret: "ts")
        
        let userAgent: UserAgent = TestUserAgent(handler: { (request, redirectURI, redirectionHandler) in
            
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
            
            do {
                
                //simulate fake redirection with wrong state
                let redirectRequest = URLRequest(url: URL(string: "ik://my.redirect.url/here/now?error=access_denied")!)
                _ = try redirectionHandler(redirectRequest)
                XCTFail()
            }
            catch {
                
            }
        })
        
        let networkClient: NetworkClient = TestNetworkClient(handler: { (request, completion) in
            
            //since state is wrong, the token request should never be executed
            XCTFail()
        })
        
        let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
        
        let response = try? await flow.authenticateAsync()
        
        XCTAssertNil(response)
    }
    
    func testErrorFromNetworkClientAsync() async {
        
        let redirectURI: URL? = URL(string: "ik://my.redirect.url/here/now")
        let state: AnyHashable? = "obi one"
        let clientAuthorizer: RequestAuthorizer? = HTTPBasicAuthorizer(clientID: "tcid", secret: "ts")
        
        let userAgent: UserAgent = TestUserAgent(handler: { (request, redirectURI, redirectionHandler) in
            
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
            
            do {
                
                //simulate successfull redirection
                let redirectRequest = URLRequest(url: URL(string: "ik://my.redirect.url/here/now?code=abc&state=obi%20one")!)
                let handled = try redirectionHandler(redirectRequest)
                XCTAssertTrue(handled)
            }
            catch {
                
                XCTFail()
            }
        })
        
        let networkClient: NetworkClient = TestNetworkClient(handler: { (request, completion) in
            
            XCTAssertEqual(request.url, URL(string: "http://foo.bar/token"))
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic dGNpZDp0cw==")
            XCTAssertNotNil(request.httpBody)
            
            guard
                let parameters = request.httpBody?.urlDecodedParameters
            else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(parameters["grant_type"], "authorization_code")
            XCTAssertEqual(parameters["code"], "abc")
            XCTAssertEqual(parameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(parameters["client_id"], nil)
            
            let data = "{\"error\":\"invalid_scope\"}".data(using: .utf8)
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 400, httpVersion: nil, headerFields: nil)
            
            completion(NetworkResponse(data: data, response: response, error: nil))
        })
        
        let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
        
        let response = try? await flow.authenticateAsync()
        
        XCTAssertNil(response)
    }
    
    func testAdditionalParametersAsync() async {
        
        let redirectURI: URL? = URL(string: "ik://my.redirect.url/here/now")
        let state: AnyHashable? = "obi one"
        let clientAuthorizer: RequestAuthorizer? = HTTPBasicAuthorizer(clientID: "tcid", secret: "ts")
        
        let userAgent: UserAgent = TestUserAgent(handler: { (request, redirectURI, redirectionHandler) in
            
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
            
            do {
                
                //simulate successfull redirection
                let redirectRequest = URLRequest(url: URL(string: "ik://my.redirect.url/here/now?code=abc&state=obi%20one")!)
                let handled = try redirectionHandler(redirectRequest)
                XCTAssertTrue(handled)
            }
            catch {
                
                XCTFail()
            }
        })
        
        let networkClient: NetworkClient = TestNetworkClient(handler: { (request, completion) in
            
            XCTAssertEqual(request.url, URL(string: "http://foo.bar/token"))
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic dGNpZDp0cw==")
            XCTAssertNotNil(request.httpBody)
            
            guard
                let parameters = request.httpBody?.urlDecodedParameters
            else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(parameters["grant_type"], "authorization_code")
            XCTAssertEqual(parameters["code"], "tampered abc")
            XCTAssertEqual(parameters["redirect_uri"], "ik://my.redirect.url/here/now")
            XCTAssertEqual(parameters["client_id"], nil)
            XCTAssertEqual(parameters["additional_parameter_2"], "ap2")
            
            let data = "{\"access_token\":\"tat\",\"token_type\":\"ttt\",\"expires_in\":1234,\"refresh_token\":\"trt\",\"scope\":\"ts1 ts2\"}".data(using: .utf8)
            let response = HTTPURLResponse(url: self.tokenEndpoint, statusCode: 200, httpVersion: nil, headerFields: nil)
            
            completion(NetworkResponse(data: data, response: response, error: nil))
        })
        
        let flow = AuthorizationCodeGrantFlow(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
        
        //set additional  parameters and override some of existing ones
        flow.additionalAuthorizationRequestParameters = ["additional_parameter_1": "ap1", "client_id": "tampered jarjar"]
        flow.additionalAccessTokenRequestParameters = ["additional_parameter_2": "ap2", "code": "tampered abc"]
        
        let response = try? await flow.authenticateAsync()
        
        XCTAssertNotNil(response)
        
        XCTAssertEqual(response?.accessToken, "tat")
        XCTAssertEqual(response?.tokenType, "ttt")
        XCTAssertEqual(response?.expiresIn, 1234)
        XCTAssertEqual(response?.refreshToken, "trt")
        XCTAssertEqual(response?.scope?.value, "ts1 ts2")
    }
}

