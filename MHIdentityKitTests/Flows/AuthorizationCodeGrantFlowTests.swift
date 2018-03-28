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
    let credentialsProvider = DefaultCredentialsProvider(username: "tu", password: "tp")
    let scope: Scope = "read write"
    
    func testSuccessWithAllArguments() {
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 3
            
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
                
                e.fulfill()
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
                
                e.fulfill()
            })
            
            let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
            
            flow.authenticate(handler: { (response, error) in
                
                XCTAssertNotNil(response)
                XCTAssertNil(error)
                
                XCTAssertEqual(response?.accessToken, "tat")
                XCTAssertEqual(response?.tokenType, "ttt")
                XCTAssertEqual(response?.expiresIn, 1234)
                XCTAssertEqual(response?.refreshToken, "trt")
                XCTAssertEqual(response?.scope?.value, "ts1 ts2")
                
                e.fulfill()
            })
        }
    }
    
    func testSuccessWithoutClientAuthorizer() {
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 3
            
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
                
                e.fulfill()
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
                
                e.fulfill()
            })
            
            let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
            
            flow.authenticate(handler: { (response, error) in
                
                XCTAssertNotNil(response)
                XCTAssertNil(error)
                
                XCTAssertEqual(response?.accessToken, "tat")
                XCTAssertEqual(response?.tokenType, "ttt")
                XCTAssertEqual(response?.expiresIn, 1234)
                XCTAssertEqual(response?.refreshToken, "trt")
                XCTAssertEqual(response?.scope?.value, "ts1 ts2")
                
                e.fulfill()
            })
        }
    }
    
    func testSuccessWithoutRedirectURI() {
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 3
            
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
                
                e.fulfill()
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
                
                e.fulfill()
            })
            
            let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
            
            flow.authenticate(handler: { (response, error) in
                
                XCTAssertNotNil(response)
                XCTAssertNil(error)
                
                XCTAssertEqual(response?.accessToken, "tat")
                XCTAssertEqual(response?.tokenType, "ttt")
                XCTAssertEqual(response?.expiresIn, 1234)
                XCTAssertEqual(response?.refreshToken, "trt")
                XCTAssertEqual(response?.scope?.value, "ts1 ts2")
                
                e.fulfill()
            })
        }
    }
    
    func testSuccessWithoutOptionalArguments() {
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 3
            
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
                
                e.fulfill()
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
                
                e.fulfill()
            })
            
            let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
            
            flow.authenticate(handler: { (response, error) in
                
                XCTAssertNotNil(response)
                XCTAssertNil(error)
                
                XCTAssertEqual(response?.accessToken, "tat")
                XCTAssertEqual(response?.tokenType, "ttt")
                XCTAssertEqual(response?.expiresIn, 1234)
                XCTAssertEqual(response?.refreshToken, "trt")
                XCTAssertEqual(response?.scope?.value, "ts1 ts2")
                
                e.fulfill()
            })
        }
    }
    
    //when the state mismatch, the flow should complete with error
    func testErrorWithInvalidState() {
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 2
            
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
                
                e.fulfill()
            })
            
            let networkClient: NetworkClient = TestNetworkClient(handler: { (request, completion) in
                
                //since state is wrong, the token request should never be executed
                XCTFail()
            })
            
            let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
            
            flow.authenticate(handler: { (response, error) in
                
                XCTAssertNil(response)
                XCTAssertNotNil(error)
                
                e.fulfill()
            })
        }
    }
    
    //When the redirect uri mismatch, the flow should wait for matching uri
    func testErrorWithRedirectURIMismatch() {
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 1
            
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
                
                e.fulfill()
            })
            
            let networkClient: NetworkClient = TestNetworkClient(handler: { (request, completion) in
                
                XCTFail()
            })
            
            let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
            
            flow.authenticate(handler: { (response, error) in
                
                XCTFail()
            })
        }
    }
    
    //When the redirect uri mismatch, the flow should wait for matching uri
    func testSuccessWithMultipleRedirections() {
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 3
            
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
                
                e.fulfill()
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
                
                e.fulfill()
            })
            
            let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
            
            flow.authenticate(handler: { (response, error) in
                
                XCTAssertNotNil(response)
                XCTAssertNil(error)
                
                XCTAssertEqual(response?.accessToken, "tat")
                XCTAssertEqual(response?.tokenType, "ttt")
                XCTAssertEqual(response?.expiresIn, 1234)
                XCTAssertEqual(response?.refreshToken, "trt")
                XCTAssertEqual(response?.scope?.value, "ts1 ts2")
                
                e.fulfill()
            })
        }
    }
    
    //when the state mismatch, the flow should complete with error
    func testErrorFromUserAgent() {
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 2
            
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
                
                e.fulfill()
            })
            
            let networkClient: NetworkClient = TestNetworkClient(handler: { (request, completion) in
                
                //since state is wrong, the token request should never be executed
                XCTFail()
            })
            
            let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
            
            flow.authenticate(handler: { (response, error) in
                
                XCTAssertNil(response)
                XCTAssertNotNil(error)
                
                e.fulfill()
            })
        }
    }
    
    func testErrorFromNetworkClient() {
        
        self.performExpectation { (e) in
            
            e.expectedFulfillmentCount = 3
            
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
                
                e.fulfill()
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
                
                e.fulfill()
            })
            
            let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
            
            flow.authenticate(handler: { (response, error) in
                
                XCTAssertNil(response)
                XCTAssertNotNil(error)
                
                e.fulfill()
            })
        }
    }
}





