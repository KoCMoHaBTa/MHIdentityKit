//
//  ImplicitGrantFlow.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 1.07.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation

//https://tools.ietf.org/html/rfc6749#section-4.2
open class ImplicitGrantFlow: AuthorizationGrantFlow {
    
    public let authorizationEndpoint: URL
    public let clientID: String
    public let redirectURI: URL
    public let scope: Scope?
    public let state: String?
    public let userAgent: UserAgent
    
    ///You can specify additional authorization request parameters. If existing key is duplicated, the one specified by this property will be used.
    public var additionalAuthorizationRequestParameters: [String: Any] = [:]
    
    //MARK: - Init
    
    /**
     Creates an instance of the receiver.
     
     - parameter tokenEndpoint: The URL of the authorization endpoint
     - parameter clientID: The client identifier as described in [Section 2.2](https://tools.ietf.org/html/rfc6749#section-2.2)
     - parameter redirectURI: As described in [Section 3.1.2](https://tools.ietf.org/html/rfc6749#section-3.1.2)
     - parameter scope: The scope of the access request as described by [Section 3.3](https://tools.ietf.org/html/rfc6749#section-3.3)
     - parameter state: An opaque value used by the client to maintain state between the request and callback. The authorization server includes this value when redirecting the user-agent back to the client. The parameter SHOULD be used for preventing cross-site request forgery as described in [Section 10.12](https://tools.ietf.org/html/rfc6749#section-10.12). Default to random UUID.
     - parameter userAgent: The user agent used to perform the authroization request and handle redirects.
     
     */
    
    public init(authorizationEndpoint: URL, clientID: String, redirectURI: URL, scope: Scope?, state: String? = NSUUID().uuidString, userAgent: UserAgent) {
        
        self.authorizationEndpoint = authorizationEndpoint
        self.clientID = clientID
        self.redirectURI = redirectURI
        self.scope = scope
        self.state = state
        self.userAgent = userAgent
    }
    
    //MARK: - Flow logic
    
    ///Build the parameters used for the [Authorization Request](https://tools.ietf.org/html/rfc6749#section-4.2.1)
    open func authorizationRequestParameters() -> [String: Any] {
        
        var parameters = [String: Any]()
        parameters["response_type"] = AuthorizationResponseType.token.rawValue
        parameters["client_id"] = clientID
        parameters["redirect_uri"] = redirectURI
        parameters["scope"] = scope?.rawValue
        parameters["state"] = state

        //merge with any additionally provided parameteres
        parameters.merge(additionalAuthorizationRequestParameters, uniquingKeysWith: { $1 })
        
        return parameters
    }
    
    ///Construct the [Authorization Request](https://tools.ietf.org/html/rfc6749#section-4.2.1) using the supplied parameters
    open func authorizationRequest(withParameters parameters: [String: Any]) -> URLRequest {
        
        let url = authorizationEndpoint +?! parameters
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        return request
    }
    
    open func validate(redirectRequest: URLRequest) async throws {
        
        guard
        redirectURI.scheme == redirectRequest.url?.scheme,
        redirectURI.host == redirectRequest.url?.host,
        redirectURI.path == redirectRequest.url?.path
        else {
        
            throw Error.redirectURIMismatch
        }
        
        //the request url must contain either (`access_token` and `token_type`) or `error` fragment parameter
        //https://tools.ietf.org/html/rfc6749#section-4.2.2.1
        let parameters = redirectRequest.url?.fragment?.urlDecodedParameters
        guard (parameters?["access_token"] != nil && parameters?["token_type"] != nil) || parameters?["error"] != nil else {

            throw Error.invalidRedirectRequestParameters
        }
    }
    
    ///Retrieves and returns the parameters for the [Access Token Response](https://tools.ietf.org/html/rfc6749#section-4.2.2) from the provided redirect request
    open func accessTokenResponseParameters(fromRedirectRequest redirectRequest: URLRequest) throws -> [String: Any] {
        
        let parameters = redirectRequest.url?.fragment?.urlDecodedParameters ?? [:]
        
        //if the error is one of the defined in the OAuth2 framework - throw it
        if let error = OAuth2Error(parameters: parameters) {
            
            throw error
        }
        
        return parameters
    }
    
    open func validate(accessTokenResponseParameters parameters: [String: Any]) async throws {
        
        guard parameters["state"] as? String == state else { throw Error.accessTokenResponseStateMismatch }
    }
    
    //MARK: - AuthorizationGrantFlow
    
    public func authenticate() async throws -> AccessTokenResponse {
        
        let authorizationRequestParameters = self.authorizationRequestParameters()
        let authorizationRequest = self.authorizationRequest(withParameters: authorizationRequestParameters)
        
        guard let redirectRequest = await userAgent.perform(authorizationRequest, redirectURI: redirectURI) else {
            
            throw Error.userAgentCancelled
        }
        
        do {
            try await validate(redirectRequest: redirectRequest)
            await userAgent.finish(with: nil)
        }
        catch {
            await userAgent.finish(with: error)
            throw error
        }
        
        let accessTokenResponseParameters = try accessTokenResponseParameters(fromRedirectRequest: redirectRequest)
        try await validate(accessTokenResponseParameters: accessTokenResponseParameters)
        
        let accessTokenResponse = try AccessTokenResponse(parameters: accessTokenResponseParameters)
        return accessTokenResponse
    }
}

extension ImplicitGrantFlow {
    
    enum Error: Swift.Error {

        ///Indicates that the redirect request does not match the redirectURI
        case redirectURIMismatch
        
        ///Indicates that the redirect request parameters are not valid.
        ///- note: The request url must contain either (`access_token` and `token_type`) or `error` fragment parameter
        case invalidRedirectRequestParameters
        
        ///Indicates that the authorization response state does not match with the provided one
        case accessTokenResponseStateMismatch
        
        ///Indicates that the user agent has been cancelled.
        ///- note: This is usually a user action, but in most cases it might be caused due to the user agent was unable to return a valid redirect request.
        case userAgentCancelled
    }
}
