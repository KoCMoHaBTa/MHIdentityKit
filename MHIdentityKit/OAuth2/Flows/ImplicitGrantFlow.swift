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
    public let state: AnyHashable?
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
    
    public init(authorizationEndpoint: URL, clientID: String, redirectURI: URL, scope: Scope?, state: AnyHashable? = NSUUID().uuidString, userAgent: UserAgent) {
        
        self.authorizationEndpoint = authorizationEndpoint
        self.clientID = clientID
        self.redirectURI = redirectURI
        self.scope = scope
        self.state = state
        self.userAgent = userAgent
    }
    
    //MARK: - Flow logic
    
    open func parameters(from authorizationRequest: AuthorizationRequest) -> [String: Any] {
        
        authorizationRequest.dictionary.merging(additionalAuthorizationRequestParameters, uniquingKeysWith: { $1 })
    }
    
    open func data(from parameters: [String: Any]) -> Data? {
        
        parameters.urlEncodedParametersData
    }
    
    open func urlRequest(from authorizationRequest: AuthorizationRequest) -> URLRequest {
        
        let parameters = parameters(from: authorizationRequest)
        let url = authorizationEndpoint +?! parameters
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        return request
    }
    
    open func perform(_ request: URLRequest, redirectURI: URL) async -> URLRequest? {
        
        await userAgent.perform(request, redirectURI: redirectURI)
    }
    
    open func authorizationResponse(from request: URLRequest) throws -> AuthorizationResponse {
        
        guard
        let url = request.url,
        let parameters = url.fragment?.urlDecodedParameters
        else {
            
            throw MHIdentityKitError.authenticationFailed(reason: MHIdentityKitError.Reason.invalidAccessTokenResponse)
        }
        
        //if the error is one of the defined in the OAuth2 framework - throw it
        if let error = OAuth2Error(parameters: parameters) {
            
            throw error
        }
        
        guard let response = AuthorizationResponse(parameters: parameters) else {
            
            throw MHIdentityKitError.authenticationFailed(reason: MHIdentityKitError.Reason.invalidAccessTokenResponse)
        }
        
        return response
    }
    
    open func validate(redirectRequest: URLRequest) async throws {
        
        guard
        redirectURI.scheme == redirectRequest.url?.scheme,
        redirectURI.host == redirectRequest.url?.host,
        redirectURI.path == redirectRequest.url?.path
        else {
        
            throw MHIdentityKitError.general(description: "Invalid redirect request", reason: "The redirect request does not match the redirectURI")

        }
        
        //the request url must contain either (`access_token` and `token_type`) or `error` fragment parameter
        //https://tools.ietf.org/html/rfc6749#section-4.2.2.1
        let parameters = redirectRequest.url?.fragment?.urlDecodedParameters
        guard (parameters?["access_token"] != nil && parameters?["token_type"] != nil) || parameters?["error"] != nil else {

            throw MHIdentityKitError.general(description: "Invalid redirect request", reason: nil)
        }
    }
    
    open func validate(_ authorizationResponse: AuthorizationResponse) async throws {
        
        guard authorizationResponse.state == state else {
            
            throw MHIdentityKitError.authenticationFailed(reason: MHIdentityKitError.Reason.invalidAuthorizationResponse)
        }
    }
    
    //MARK: - AuthorizationGrantFlow
    
    public func authenticate() async throws -> AccessTokenResponse {
        
        let authorizationRequest = AuthorizationRequest(clientID: clientID, redirectURI: redirectURI, scope: scope, state: state)
        let authorizationURLRequest = urlRequest(from: authorizationRequest)
        
        guard let redirectRequest = await perform(authorizationURLRequest, redirectURI: redirectURI) else {
            
            throw MHIdentityKitError.general(description: "UserAgent has been cancelled", reason: "The UserAgent was unable to return a valid redirect request.")
        }
        
        do {
            try await validate(redirectRequest: redirectRequest)
            await userAgent.finish(with: nil)
        }
        catch {
            await userAgent.finish(with: error)
            throw error
        }
        
        let authorizationResponse = try authorizationResponse(from: redirectRequest)
        let accessTokenResponse = AccessTokenResponse(accessToken: authorizationResponse.accessToken, tokenType: authorizationResponse.tokenType, expiresIn: authorizationResponse.expiresIn, refreshToken: nil, scope: authorizationResponse.scope)
        return accessTokenResponse
    }
}

extension ImplicitGrantFlow {
    
    //https://tools.ietf.org/html/rfc6749#section-4.2.1
    public struct AuthorizationRequest {
        
        public let responseType: AuthorizationResponseType = .token
        public var clientID: String
        public var redirectURI: URL?
        public var scope: Scope?
        public var state: AnyHashable?
        
        public init(clientID: String, redirectURI: URL?, scope: Scope?, state: AnyHashable?) {
            
            self.clientID = clientID
            self.redirectURI = redirectURI
            self.scope = scope
            self.state = state
        }
        
        public var dictionary: [String: Any] {
            
            var dictionary = [String: Any]()
            dictionary["response_type"] = responseType.rawValue
            dictionary["client_id"] = clientID
            dictionary["redirect_uri"] = redirectURI
            dictionary["scope"] = scope?.rawValue
            dictionary["state"] = state
            
            return dictionary
        }
    }
    
    //https://tools.ietf.org/html/rfc6749#section-4.2.2
    //In the implicit flow, the authorization response constains the access token
    public struct AuthorizationResponse {
        
        public let accessToken: String
        public let tokenType: String
        public let expiresIn: TimeInterval?
        public let scope: Scope?
        public let state: AnyHashable?
        
        public init(accessToken: String, tokenType: String, expiresIn: TimeInterval?, scope: Scope?, state: AnyHashable?) {
            
            self.accessToken = accessToken
            self.tokenType = tokenType
            self.expiresIn = expiresIn
            self.scope = scope
            self.state = state
        }
        
        public init?(parameters: [String: Any]) {
            
            guard
            let accessToken = parameters["access_token"] as? String,
            let tokenType = parameters["token_type"] as? String
            else {
                
                return nil
            }
            
            let expiresIn: TimeInterval?
            if let value = parameters["expires_in"] as? String {
                
                expiresIn = TimeInterval(value)
            }
            else {
                
                expiresIn = nil
            }
            
            let scope: Scope?
            if let value = parameters["scope"] as? String {
                
                scope = Scope(rawValue: value)
            }
            else {
                
                scope = nil
            }
            
            let state = parameters["state"] as? AnyHashable
            
            self.init(accessToken: accessToken, tokenType: tokenType, expiresIn: expiresIn, scope: scope, state: state)
        }
    }
}
