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
    public let redirectURI: URL?
    public let scope: Scope?
    public let state: AnyHashable?
    public let clientAuthorizer: RequestAuthorizer?
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
     - parameter state: An opaque value used by the client to maintain state between the request and callback. The authorization server includes this value when redirecting the user-agent back to the client. The parameter SHOULD be used for preventing cross-site request forgery as described in [Section 10.12](https://tools.ietf.org/html/rfc6749#section-10.12)
     - parameter clientAuthorizer: An optional authorizer used to authorize the authentication request.
     - parameter networkClient: A network client used to perform the authentication request.
     
     */
    
    public init(authorizationEndpoint: URL, clientID: String, redirectURI: URL?, scope: Scope?, state: AnyHashable?, clientAuthorizer: RequestAuthorizer?, userAgent: UserAgent) {
        
        self.authorizationEndpoint = authorizationEndpoint
        self.clientID = clientID
        self.redirectURI = redirectURI
        self.scope = scope
        self.state = state
        self.clientAuthorizer = clientAuthorizer
        self.userAgent = userAgent
    }
    
    /**
     Creates an instance of the receiver.
     
     - parameter tokenEndpoint: The URL of the authorization endpoint
     - parameter clientID: The client identifier as described in [Section 2.2](https://tools.ietf.org/html/rfc6749#section-2.2)
     - parameter secret: The secret, used to authorize confidential clients as described in [Section 4.1.3](https://tools.ietf.org/html/rfc6749#section-4.1.3) and [Section 3.2.1](https://tools.ietf.org/html/rfc6749#section-3.2.1)
     - parameter redirectURI: As described in [Section 3.1.2](https://tools.ietf.org/html/rfc6749#section-3.1.2)
     - parameter scope: The scope of the access request as described by [Section 3.3](https://tools.ietf.org/html/rfc6749#section-3.3)
     - parameter networkClient: A network client used to perform the authentication request.
     
     */
    
    public convenience init(authorizationEndpoint: URL, clientID: String, secret: String?, redirectURI: URL?, scope: Scope?, userAgent: UserAgent) {
        
        var clientAuthorizer: RequestAuthorizer?
        if let secret = secret {
            
            clientAuthorizer = HTTPBasicAuthorizer(clientID: clientID, secret: secret)
        }
        
        self.init(authorizationEndpoint: authorizationEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: NSUUID().uuidString, clientAuthorizer: clientAuthorizer, userAgent: userAgent)
    }
    
    /**
     Creates an instance of the receiver.
     
     - parameter tokenEndpoint: The URL of the authorization endpoint
     - parameter tokenEndpoint: The URL of the token endpoint
     - parameter clientID: The client identifier as described in [Section 2.2](https://tools.ietf.org/html/rfc6749#section-2.2)
     - parameter redirectURI: As described in [Section 3.1.2](https://tools.ietf.org/html/rfc6749#section-3.1.2)
     - parameter scope: The scope of the access request as described by [Section 3.3](https://tools.ietf.org/html/rfc6749#section-3.3)
     - parameter networkClient: A network client used to perform the authentication request.
     
     */
    
    public convenience init(authorizationEndpoint: URL, clientID: String, redirectURI: URL?, scope: Scope?, userAgent: UserAgent) {
        
        self.init(authorizationEndpoint: authorizationEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: NSUUID().uuidString, clientAuthorizer: nil, userAgent: userAgent)
    }
    
    //MARK: - Flow logic
    
    open func parameters(from authorizationRequest: AuthorizationRequest) -> [String: Any] {
        
        return authorizationRequest.dictionary.merging(self.additionalAuthorizationRequestParameters, uniquingKeysWith: { $1 })
    }
    
    open func data(from parameters: [String: Any]) -> Data? {
        
        return parameters.urlEncodedParametersData
    }
    
    open func urlRequest(from authorizationRequest: AuthorizationRequest) -> URLRequest {
        
        let parameters = self.parameters(from: authorizationRequest)
        let url = self.authorizationEndpoint +?! parameters
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        return request
    }
    
    open func authorize(accesTokenURLRequest: URLRequest, handler: @escaping (URLRequest, Error?) -> Void) {
        
        guard let clientAuthorizer = self.clientAuthorizer else {
            
            handler(accesTokenURLRequest, nil)
            return
        }
        
        clientAuthorizer.authorize(request: accesTokenURLRequest, handler: handler)
    }
    
    open func perform(_ request: URLRequest, redirectURI: URL?, redirectionHandler: @escaping (URLRequest) throws -> Bool) {
        
        self.userAgent.perform(request, redirectURI: redirectURI, redirectionHandler: redirectionHandler)
    }
    
    open func authorizationResponse(from request: URLRequest) throws -> AuthorizationResponse {
        
        guard
        let url = request.url,
        let parameters = url.fragment?.urlDecodedParameters
        else {
            
            throw MHIdentityKitError.authenticationFailed(reason: MHIdentityKitError.Reason.invalidAccessTokenResponse)
        }
        
        //if the error is one of the defined in the OAuth2 framework - throw it
        if let error = ErrorResponse(parameters: parameters) {
            
            throw error
        }
        
        guard let response = AuthorizationResponse(parameters: parameters) else {
            
            throw MHIdentityKitError.authenticationFailed(reason: MHIdentityKitError.Reason.invalidAccessTokenResponse)
        }
        
        return response
    }
    
    open func canHandle(redirectRequest: URLRequest) -> Bool {
        
        //if redirectURI is provided
        if let redirectURI = self.redirectURI {

            //it must match with the url of the request, by ignoring the query parameters
            guard redirectURI.scheme == redirectRequest.url?.scheme, redirectURI.host == redirectRequest.url?.host, redirectURI.path == redirectRequest.url?.path else {

                return false
            }
        }

        //the request url must contain either `code` or `error` fragment parameter
        //https://tools.ietf.org/html/rfc6749#section-4.2.2.1
        let parameters = redirectRequest.url?.fragment?.urlDecodedParameters
        guard (parameters?["access_token"] != nil && parameters?["token_type"] != nil) || parameters?["error"] != nil else {

            return false
        }

        return true
    }
    
    open func validate(_ authorizationResponse: AuthorizationResponse) throws {
        
        guard authorizationResponse.state == self.state else {
            
            throw MHIdentityKitError.authenticationFailed(reason: MHIdentityKitError.Reason.invalidAuthorizationResponse)
        }
    }
    
    //MARK: - AuthorizationGrantFlow
    
    public func authenticate(handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
        
        let authorizationRequest = AuthorizationRequest(clientID: self.clientID, redirectURI: self.redirectURI, scope: self.scope, state: self.state)
        let authorizationURLRequest = self.urlRequest(from: authorizationRequest)
        
        self.perform(authorizationURLRequest, redirectURI: self.redirectURI) { [weak self] (redirectRequest) throws -> Bool in
            
            //utility to fail and complete
            func fail(with error: Error) -> Error  {
                
                handler(nil, error)
                return error
            }
            
            //utility to try or fail and complete
            func orFail<T>(_ closure: @autoclosure () throws -> T) throws -> T {
                
                do {
                    
                    return try closure()
                }
                catch {
                    
                    throw fail(with: error)
                }
            }
            
            //if self was deallocated, there is no point to continue
            guard let _self = self else {
                
                throw fail(with: MHIdentityKitError.authenticationFailed(reason: MHIdentityKitError.Reason.general(message: "Flow was deallocated")))
            }
            
            //check if the redirectRequest can be handled
            guard _self.canHandle(redirectRequest: redirectRequest) else {
                
                return false
            }
            
            //create the access token response and validate it
            let authorizationResponse = try orFail(_self.authorizationResponse(from: redirectRequest))
            try orFail(_self.validate(authorizationResponse))
            
            DispatchQueue.main.async {
                
                let accessTokenResponse = AccessTokenResponse(accessToken: authorizationResponse.accessToken, tokenType: authorizationResponse.tokenType, expiresIn: authorizationResponse.expiresIn, refreshToken: nil, scope: authorizationResponse.scope)
                handler(accessTokenResponse, nil)
            }
            
            return true
        }
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
        
        public init(clientID: String, redirectURI: URL?, scope: Scope? = nil, state: AnyHashable? = nil) {
            
            self.clientID = clientID
            self.redirectURI = redirectURI
            self.scope = scope
            self.state = state
        }
        
        public var dictionary: [String: Any] {
            
            var dictionary = [String: Any]()
            dictionary["response_type"] = self.responseType.rawValue
            dictionary["client_id"] = self.clientID
            dictionary["redirect_uri"] = self.redirectURI
            dictionary["scope"] = self.scope?.value
            dictionary["state"] = self.state
            
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
