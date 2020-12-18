//
//  AuthorizationCodeGrantFlow.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 27.03.18.
//  Copyright © 2018 Milen Halachev. All rights reserved.
//

import Foundation

//https://tools.ietf.org/html/rfc6749#section-4.1
open class AuthorizationCodeGrantFlow: AuthorizationGrantFlow {
    
    public let authorizationEndpoint: URL
    public let tokenEndpoint: URL
    public let clientID: String
    public let redirectURI: URL?
    public let scope: Scope?
    public let state: AnyHashable?
    public let clientAuthorizer: RequestAuthorizer?
    public let userAgent: UserAgent
    public let networkClient: NetworkClient
    
    ///You can specify additional authorization request parameters. If existing key is duplicated, the one specified by this property will be used.
    public var additionalAuthorizationRequestParameters: [String: Any] = [:]
    
    ///You can specify additional access token request parameters. If existing key is duplicated, the one specified by this property will be used.
    public var additionalAccessTokenRequestParameters: [String: Any] = [:]
    
    //MARK: - Init
    
    /**
     Creates an instance of the receiver.
     
     - parameter authorizationEndpoint: The URL of the authorization endpoint
     - parameter tokenEndpoint: The URL of the token endpoint
     - parameter clientID: The client identifier as described in [Section 2.2](https://tools.ietf.org/html/rfc6749#section-2.2)
     - parameter redirectURI: As described in [Section 3.1.2](https://tools.ietf.org/html/rfc6749#section-3.1.2)
     - parameter scope: The scope of the access request as described by [Section 3.3](https://tools.ietf.org/html/rfc6749#section-3.3)
     - parameter state: An opaque value used by the client to maintain state between the request and callback. The authorization server includes this value when redirecting the user-agent back to the client. The parameter SHOULD be used for preventing cross-site request forgery as described in [Section 10.12](https://tools.ietf.org/html/rfc6749#section-10.12)
     - parameter clientAuthorizer: An optional authorizer used to authorize the authentication request.
     - parameter userAgent: The user agent used to perform the authroization request and handle redirects.
     - parameter networkClient: A network client used to perform the authentication request.
     
     */

    public init(authorizationEndpoint: URL, tokenEndpoint: URL, clientID: String, redirectURI: URL?, scope: Scope?, state: AnyHashable? = NSUUID().uuidString, clientAuthorizer: RequestAuthorizer?, userAgent: UserAgent, networkClient: NetworkClient = _defaultNetworkClient) {

        self.authorizationEndpoint = authorizationEndpoint
        self.tokenEndpoint = tokenEndpoint
        self.clientID = clientID
        self.redirectURI = redirectURI
        self.scope = scope
        self.state = state
        self.clientAuthorizer = clientAuthorizer
        self.userAgent = userAgent
        self.networkClient = networkClient
    }
    
    /**
     Creates an instance of the receiver.
     
     - parameter authorizationEndpoint: The URL of the authorization endpoint
     - parameter tokenEndpoint: The URL of the token endpoint
     - parameter clientID: The client identifier as described in [Section 2.2](https://tools.ietf.org/html/rfc6749#section-2.2)
     - parameter secret: The secret, used to authorize confidential clients as described in [Section 4.1.3](https://tools.ietf.org/html/rfc6749#section-4.1.3) and [Section 3.2.1](https://tools.ietf.org/html/rfc6749#section-3.2.1)
     - parameter redirectURI: As described in [Section 3.1.2](https://tools.ietf.org/html/rfc6749#section-3.1.2)
     - parameter scope: The scope of the access request as described by [Section 3.3](https://tools.ietf.org/html/rfc6749#section-3.3)
     - parameter userAgent: The user agent used to perform the authroization request and handle redirects.
     - parameter networkClient: A network client used to perform the authentication request.
     
     */
    
    public convenience init(authorizationEndpoint: URL, tokenEndpoint: URL, clientID: String, secret: String?, redirectURI: URL?, scope: Scope?, state: AnyHashable? = NSUUID().uuidString, userAgent: UserAgent, networkClient: NetworkClient = _defaultNetworkClient) {
        
        var clientAuthorizer: RequestAuthorizer?
        if let secret = secret {
            
            clientAuthorizer = HTTPBasicAuthorizer(clientID: clientID, secret: secret)
        }
        
        self.init(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
    }
    
    //MARK: - Flow logic
    
    ///Build the parameters used for the [Authorization Request](https://tools.ietf.org/html/rfc6749#section-4.1.1)
    open func authorizationRequestParameters() -> [String: Any] {
        
        var parameters = [String: Any]()
        parameters["response_type"] = AuthorizationResponseType.code.rawValue
        parameters["client_id"] = self.clientID
        parameters["redirect_uri"] = self.redirectURI
        parameters["scope"] = self.scope?.value
        parameters["state"] = self.state

        //merge with any additionally provided parameteres
        parameters.merge(self.additionalAuthorizationRequestParameters, uniquingKeysWith: { $1 })
        
        return parameters
    }
    
    ///Construct the [Authorization Request](https://tools.ietf.org/html/rfc6749#section-4.1.1) using the supplied parameters
    open func authorizationRequest(withParameters parameters: [String: Any]) -> URLRequest {
        
        let url = self.authorizationEndpoint +?! parameters
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        return request
    }
    
    ///Determine whenever the provided redirect request can be handled
    open func canHandle(redirectRequest: URLRequest) -> Bool {
        
        //if redirectURI is provided
        if let redirectURI = self.redirectURI {
            
            //it must match with the url of the request, by ignoring the query parameters
            guard
            redirectURI.scheme == redirectRequest.url?.scheme,
            redirectURI.host == redirectRequest.url?.host,
            redirectURI.path == redirectRequest.url?.path
            else {
            
                return false
            }
        }
        
        //the request url must contain either `code` or `error` query parameter
        let parameters = redirectRequest.url?.query?.urlDecodedParameters
        guard parameters?["code"] != nil || parameters?["error"] != nil else {
            
            return false
        }
        
        return true
    }
    
    ///Retrieves and returns the parameters for the [Authorization Response](https://tools.ietf.org/html/rfc6749#section-4.1.2) from the provided redirect request
    open func authorizationResponseParameters(fromRedirectRequest redirectRequest: URLRequest) throws -> [String: Any] {
        
        guard
        let url = redirectRequest.url,
        let parameters = url.query?.urlDecodedParameters
        else {
            
            throw MHIdentityKitError.authenticationFailed(reason: MHIdentityKitError.Reason.invalidAuthorizationResponse)
        }
        
        //if the error is one of the defined in the OAuth2 framework - throw it
        if let error = ErrorResponse(parameters: parameters) {
            
            throw error
        }
        
        return parameters
    }
    
    ///Validates the [Authorization Response](https://tools.ietf.org/html/rfc6749#section-4.1.2) parameters
    open func validate(authorizationResponseParameters parameters: [String: Any]) throws {
        
        //the 'code' should be present and the 'state' sohuld not be tampered
        guard parameters["code"] != nil && parameters["state"] as? AnyHashable == self.state else {
            
            throw MHIdentityKitError.authenticationFailed(reason: MHIdentityKitError.Reason.invalidAuthorizationResponse)
        }
    }
    
    ///Build the parameteres used for the [Access Token Request](https://tools.ietf.org/html/rfc6749#section-4.1.3)
    open func accessTokenRequestParameters(fromAuthorizationResponseParameters parameters: [String: Any]) throws -> [String: Any] {
        
        //get the code from the autorization response
        let code = parameters["code"]
        
        var parameters = [String: Any]()
        parameters["grant_type"] = GrantType.authorizationCode.rawValue
        parameters["code"] = code
        parameters["redirect_uri"] = self.redirectURI
        parameters["client_id"] = self.clientAuthorizer == nil ? self.clientID : nil
        
        //merge with any additionally provided parameteres
        parameters.merge(self.additionalAccessTokenRequestParameters, uniquingKeysWith: { $1 })
        
        return parameters
    }
    
    ///Construct the [Access Token Request](https://tools.ietf.org/html/rfc6749#section-4.1.3) using the supplied parameters
    open func accessTokenRequest(withParameteres parameteres: [String: Any]) -> URLRequest {
        
        var request = URLRequest(url: self.tokenEndpoint)
        request.httpMethod = "POST"
        request.httpBody = parameteres.urlEncodedParametersData
        
        return request
    }
    
    ///Authorize the access token request, if needed
    open func authorize(accesTokenRequest: URLRequest, handler: @escaping (URLRequest, Error?) -> Void) {
        
        guard let clientAuthorizer = self.clientAuthorizer else {
            
            handler(accesTokenRequest, nil)
            return
        }
        
        clientAuthorizer.authorize(request: accesTokenRequest, handler: handler)
    }
    
    ///Retrieves and returns the parameters for the [Access Token Response](https://tools.ietf.org/html/rfc6749#section-4.1.4) from the provided network response
    open func accessTokenResponse(from networkResponse: NetworkResponse) throws -> AccessTokenResponse {
     
        return try AccessTokenResponseHandler().handle(response: networkResponse)
    }
    
    ///Validates the [Access Token Response](https://tools.ietf.org/html/rfc6749#section-4.1.4) parameters
    open func validate(accessTokenResponse: AccessTokenResponse) throws {
        
        //nothing to validate here
    }
    
    //MARK: - AuthorizationGrantFlow
    
    open func authenticate(handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
        
        let authorizationRequestParameters = self.authorizationRequestParameters()
        let authorizationRequest = self.authorizationRequest(withParameters: authorizationRequestParameters)
        
        self.userAgent.perform(authorizationRequest, redirectURI: self.redirectURI) { [weak self] (redirectRequest) throws -> Bool in
            
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
            
            //create the authorizagtion response and validate it
            let authorizationResponseParameters = try orFail(_self.authorizationResponseParameters(fromRedirectRequest: redirectRequest))
            try orFail(_self.validate(authorizationResponseParameters: authorizationResponseParameters))
            
            //prepare for authentication
            let accessTokenRequestParameters = try _self.accessTokenRequestParameters(fromAuthorizationResponseParameters: authorizationResponseParameters)
            let accesTokenRequest = _self.accessTokenRequest(withParameteres: accessTokenRequestParameters)
            
            //authorize the token request
            _self.authorize(accesTokenRequest: accesTokenRequest, handler: { (accesTokenRequest, error) in
                
                guard error == nil else {
                    
                    DispatchQueue.main.async {
                        
                        handler(nil, error)
                    }
                    
                    return
                }
                
                //perform the token request
                _self.networkClient.perform(accesTokenRequest, completion: { (networkResponse) in
                    
                    do {
                        
                        let accessTokenResponse = try _self.accessTokenResponse(from: networkResponse)
                        try _self.validate(accessTokenResponse: accessTokenResponse)
                        
                        DispatchQueue.main.async {
                            
                            handler(accessTokenResponse, nil)
                        }
                    }
                    catch {
                        
                        DispatchQueue.main.async {
                            
                            handler(nil, error)
                        }
                    }
                })
            })
            
            return true
        }
    }
}
