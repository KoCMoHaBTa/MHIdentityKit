//
//  ImplicitGrantFlowAsyncTests.swift
//  MHIdentityKit
//
//  Created by Lyubomir Yordanov on 8/5/22.
//  Copyright © 2022 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import MHIdentityKit

@available(iOS 13, tvOS 13.0.0, macOS 10.15, *)
class ImplicitGrantFlowAsyncTests: XCTestCase {
    
    let authorizationEndpoint = URL(string: "http://foo.bar/auth")!
    let clientID = "jarjar"
    let credentialsProvider = AnyCredentialsProvider(username: "tu", password: "tp")
    let scope: Scope = "read write"
    
    func testAccessTokenResponseBuilding() {
     
        let url = URL(string: "http://example.com/cb#access_token=2YotnFZFEjr1zCsicMWpAA&state=xyz&token_type=example&expires_in=3600&scope=sc1%20sc2")!
        let parameters = url.fragment!.urlDecodedParameters
        let response = ImplicitGrantFlow.AuthorizationResponse(parameters: parameters)
        
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.accessToken, "2YotnFZFEjr1zCsicMWpAA")
        XCTAssertEqual(response?.tokenType, "example")
        XCTAssertEqual(response?.expiresIn, 3600)
        XCTAssertEqual(response?.scope, "sc1 sc2")
        XCTAssertEqual(response?.state, "xyz")
    }
    
    func testSuccessWithAllArgumentsAsync() async {
        
        let redirectURI: URL? = URL(string: "ik://my.redirect.url/here/now")
        let state: AnyHashable? = "obi one"
        
        let userAgent: UserAgent = TestUserAgent(handler: { (request, redirectURI, redirectionHandler) in
            
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
            
            do {
                
                //simulate successfull redirection
                let redirectRequest = URLRequest(url: URL(string: "ik://my.redirect.url/here/now#access_token=tat&token_type=ttt&expires_in=1234&scope=ts1%20ts2&state=obi%20one")!)
                let handled = try redirectionHandler(redirectRequest)
                XCTAssertTrue(handled)
            }
            catch {
                
                XCTFail()
            }
        })
        
        let flow: AuthorizationGrantFlow = ImplicitGrantFlow(authorizationEndpoint: authorizationEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, userAgent: userAgent)
        
        let response = try? await flow.authenticateAsync()
        
        XCTAssertNotNil(response)
        
        XCTAssertEqual(response?.accessToken, "tat")
        XCTAssertEqual(response?.tokenType, "ttt")
        XCTAssertEqual(response?.expiresIn, 1234)
        XCTAssertNil(response?.refreshToken)
        XCTAssertEqual(response?.scope?.value, "ts1 ts2")
    }
    
    func testSuccessWithoutRedirectURIAsync() async {
        
        let redirectURI: URL? = nil
        let state: AnyHashable? = "obi one"
        
        let userAgent: UserAgent = TestUserAgent(handler: { (request, redirectURI, redirectionHandler) in
            
            XCTAssertEqual(request.url?.scheme, "http")
            XCTAssertEqual(request.url?.host, "foo.bar")
            XCTAssertEqual(request.url?.path, "/auth")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["response_type"], "token")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["client_id"], "jarjar")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["redirect_uri"], nil)
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["scope"], "read write")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["state"], "obi one")
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(redirectURI, nil)
            
            do {
                
                //simulate successfull redirection
                let redirectRequest = URLRequest(url: URL(string: "ik://my.redirect.url/here/now#access_token=tat&token_type=ttt&expires_in=1234&scope=ts1%20ts2&state=obi%20one")!)
                let handled = try redirectionHandler(redirectRequest)
                XCTAssertTrue(handled)
            }
            catch {
                
                XCTFail()
            }
        })
        
        let flow: AuthorizationGrantFlow = ImplicitGrantFlow(authorizationEndpoint: authorizationEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, userAgent: userAgent)
        
        let response = try? await flow.authenticateAsync()
        
        XCTAssertNotNil(response)
        
        XCTAssertEqual(response?.accessToken, "tat")
        XCTAssertEqual(response?.tokenType, "ttt")
        XCTAssertEqual(response?.expiresIn, 1234)
        XCTAssertNil(response?.refreshToken)
        XCTAssertEqual(response?.scope?.value, "ts1 ts2")
    }
    
    func testSuccessWithoutOptionalArgumentsAsync() async {
        
        let redirectURI: URL? = nil
        let state: AnyHashable? = nil
        
        let userAgent: UserAgent = TestUserAgent(handler: { (request, redirectURI, redirectionHandler) in
            
            XCTAssertEqual(request.url?.scheme, "http")
            XCTAssertEqual(request.url?.host, "foo.bar")
            XCTAssertEqual(request.url?.path, "/auth")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["response_type"], "token")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["client_id"], "jarjar")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["redirect_uri"], nil)
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["scope"], "read write")
            XCTAssertEqual(request.url!.query!.urlDecodedParameters["state"], nil)
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(redirectURI, nil)
            
            do {
                
                //simulate successfull redirection
                let redirectRequest = URLRequest(url: URL(string: "ik://my.redirect.url/here/now#access_token=tat&token_type=ttt&expires_in=1234&scope=ts1%20ts2")!)
                let handled = try redirectionHandler(redirectRequest)
                XCTAssertTrue(handled)
            }
            catch {
                
                XCTFail()
            }
        })
        
        let flow: AuthorizationGrantFlow = ImplicitGrantFlow(authorizationEndpoint: authorizationEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, userAgent: userAgent)
        
        let response = try? await flow.authenticateAsync()
        
        XCTAssertNotNil(response)
        
        XCTAssertEqual(response?.accessToken, "tat")
        XCTAssertEqual(response?.tokenType, "ttt")
        XCTAssertEqual(response?.expiresIn, 1234)
        XCTAssertNil(response?.refreshToken)
        XCTAssertEqual(response?.scope?.value, "ts1 ts2")
    }

    //when the state mismatch, the flow should complete with error
    func testErrorWithInvalidState() async {

            let redirectURI: URL? = URL(string: "ik://my.redirect.url/here/now")
            let state: AnyHashable? = "obi one"

            let userAgent: UserAgent = TestUserAgent(handler: { (request, redirectURI, redirectionHandler) in

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

                do {

                    //simulate fake redirection with wrong state
                    let redirectRequest = URLRequest(url: URL(string: "ik://my.redirect.url/here/now#access_token=tat&token_type=ttt&expires_in=1234&scope=ts1%20ts2&state=fake")!)
                    _ = try redirectionHandler(redirectRequest)
                    XCTFail()
                }
                catch {

                }
            })

            let flow: AuthorizationGrantFlow = ImplicitGrantFlow(authorizationEndpoint: authorizationEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, userAgent: userAgent)

            let response = try? await flow.authenticateAsync()

            XCTAssertNil(response)
    }

    //When the redirect uri mismatch, the flow should wait for matching uri
    func testErrorWithRedirectURIMismatchAsync() {
        
        let redirectURI: URL? = URL(string: "ik://my.redirect.url/here/now")
        let state: AnyHashable? = "obi one"
                
        let userAgent: UserAgent = TestUserAgent(handler: { (request, redirectURI, redirectionHandler) in
            
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
            
            do {

                //simulate fake redirection with wrong url
                let redirectRequest = URLRequest(url: URL(string: "ik://my.scam.url/here/now#access_token=tat&token_type=ttt&expires_in=1234&scope=ts1%20ts2&state=obi%20one")!)
                let handled = try redirectionHandler(redirectRequest)
                XCTAssertFalse(handled)
            }
            catch {

                XCTFail()
            }
        })
        
        let flow: AuthorizationGrantFlow = ImplicitGrantFlow(authorizationEndpoint: authorizationEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, userAgent: userAgent)

        Task.init {
        
            _ = try? await flow.authenticateAsync()
            XCTFail()
        }
    }

    //When the redirect uri mismatch, the flow should wait for matching uri
    func testSuccessWithMultipleRedirectionsAsync() async {
        
        let redirectURI: URL? = URL(string: "ik://my.redirect.url/here/now")
        let state: AnyHashable? = "obi one"
        
        let userAgent: UserAgent = TestUserAgent(handler: { (request, redirectURI, redirectionHandler) in
            
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
            
            do {
                
                //simulate mismatch redirection
                let handled = try redirectionHandler(URLRequest(url: URL(string: "ik://my.fake1.url/here/now#access_token=tat&token_type=ttt&expires_in=1234&scope=ts1%20ts2&state=obi%20one")!))
                XCTAssertFalse(handled)
                
                //simulate mismatch redirection
                let handled1 = try redirectionHandler(URLRequest(url: URL(string: "ik://fake.redirect.url/here/now#access_token=tat&token_type=ttt&expires_in=1234&scope=ts1%20ts2&state=obi%20one")!))
                XCTAssertFalse(handled1)
                
                //simulate mismatch redirection
                let handled2 = try redirectionHandler(URLRequest(url: URL(string: "ik://my.redirect.fake/here/now#access_token=tat&token_type=ttt&expires_in=1234&scope=ts1%20ts2&state=obi%20one")!))
                XCTAssertFalse(handled2)
                
                //simulate mismatch redirection
                let handled3 = try redirectionHandler(URLRequest(url: URL(string: "ik://my.redirect.url/here/fake#access_token=tat&token_type=ttt&expires_in=1234&scope=ts1%20ts2&state=obi%20one")!))
                XCTAssertFalse(handled3)
                
                //simulate mismatch redirection
                let handled4 = try redirectionHandler(URLRequest(url: URL(string: "ik://my.redirect.url/here/now")!))
                XCTAssertFalse(handled4)
                
                //simulate successfull redirection
                let handled5 = try redirectionHandler(URLRequest(url: URL(string: "ik://my.redirect.url/here/now#access_token=tat&token_type=ttt&expires_in=1234&scope=ts1%20ts2&state=obi%20one")!))
                XCTAssertTrue(handled5)
            }
            catch {
                
                XCTFail()
            }
        })
        
        let flow: AuthorizationGrantFlow = ImplicitGrantFlow(authorizationEndpoint: authorizationEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, userAgent: userAgent)
        
        let response = try? await flow.authenticateAsync()
        
        XCTAssertNotNil(response)
        
        XCTAssertEqual(response?.accessToken, "tat")
        XCTAssertEqual(response?.tokenType, "ttt")
        XCTAssertEqual(response?.expiresIn, 1234)
        XCTAssertNil(response?.refreshToken)
        XCTAssertEqual(response?.scope?.value, "ts1 ts2")
    }

    //when the state mismatch, the flow should complete with error
    func testErrorFromUserAgentAsync() async {
        
        let redirectURI: URL? = URL(string: "ik://my.redirect.url/here/now")
        let state: AnyHashable? = "obi one"
        
        let userAgent: UserAgent = TestUserAgent(handler: { (request, redirectURI, redirectionHandler) in
            
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
            
            do {
                
                //simulate fake redirection with wrong state
                let redirectRequest = URLRequest(url: URL(string: "ik://my.redirect.url/here/now#error=access_denied")!)
                _ = try redirectionHandler(redirectRequest)
                XCTFail()
            }
            catch {
                
            }
        })
        
        let flow: AuthorizationGrantFlow = ImplicitGrantFlow(authorizationEndpoint: authorizationEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, userAgent: userAgent)
        
        let response = try? await flow.authenticateAsync()
        
        XCTAssertNil(response)
    }

    func testAdditionalParametersAsync() async {
        
        let redirectURI: URL? = URL(string: "ik://my.redirect.url/here/now")
        let state: AnyHashable? = "obi one"
        
        let userAgent: UserAgent = TestUserAgent(handler: { (request, redirectURI, redirectionHandler) in
            
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
            
            do {
                
                //simulate successfull redirection
                let redirectRequest = URLRequest(url: URL(string: "ik://my.redirect.url/here/now#access_token=tat&token_type=ttt&expires_in=1234&scope=ts1%20ts2&state=obi%20one")!)
                let handled = try redirectionHandler(redirectRequest)
                XCTAssertTrue(handled)
            }
            catch {
                
                XCTFail()
            }
        })
        
        let flow = ImplicitGrantFlow(authorizationEndpoint: authorizationEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, userAgent: userAgent)
        
        //set additional  parameters and override some of existing ones
        flow.additionalAuthorizationRequestParameters = ["additional_parameter_1": "ap1", "client_id": "tampered jarjar"]
        
        let response = try? await flow.authenticateAsync()
        
        XCTAssertNotNil(response)
        
        XCTAssertEqual(response?.accessToken, "tat")
        XCTAssertEqual(response?.tokenType, "ttt")
        XCTAssertEqual(response?.expiresIn, 1234)
        XCTAssertNil(response?.refreshToken)
        XCTAssertEqual(response?.scope?.value, "ts1 ts2")
    }
}

