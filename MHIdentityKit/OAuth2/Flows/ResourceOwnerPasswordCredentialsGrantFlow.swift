//
//  ResourceOwnerPasswordCredentialsGrantFlow.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 4/12/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

//https://tools.ietf.org/html/rfc6749#section-1.3.3
//https://tools.ietf.org/html/rfc6749#section-4.3
open class ResourceOwnerPasswordCredentialsGrantFlow: AuthorizationGrantFlow {
    
    public let tokenEndpoint: URL
    public let credentialsProvider: CredentialsProvider
    public let scope: Scope?
    public let clientAuthorizer: RequestAuthorizer
    public let networkClient: NetworkClient
    
    ///You can specify additional access token request parameters. If existing key is duplicated, the one specified by this property will be used.
    public var additionalAccessTokenRequestParameters: [String: Any] = [:]

    //MARK: - Init
    
    /**
     Creates an instance of the receiver.

     - parameter tokenEndpoint: The URL of the token endpoint
     - parameter credentialsProvider: A credentials provider used to retrieve username and password in order authenticate the client. This could be your login view controller for example.
     - parameter scope: The scope of the access request.
     - parameter clientAuthorizer: An authorizer used to authorize the authentication request. Usually an instance of HTTPBasicAuthorizer with your clientID and secret.
     - parameter networkClient: A network client used to perform the authentication request.
     
     */
    
    public init(tokenEndpoint: URL, credentialsProvider: CredentialsProvider, scope: Scope?, clientAuthorizer: RequestAuthorizer, networkClient: NetworkClient = _defaultNetworkClient) {
        
        self.tokenEndpoint = tokenEndpoint
        self.credentialsProvider = credentialsProvider
        self.scope = scope
        self.clientAuthorizer = clientAuthorizer
        self.networkClient = networkClient
    }
    
    //MARK: - Flow logic
    
    open func parameters(from accessTokenRequest: AccessTokenRequest) -> [String: Any] {
        
        return accessTokenRequest.dictionary.merging(self.additionalAccessTokenRequestParameters, uniquingKeysWith: { $1 })
    }
    
    open func data(from parameters: [String: Any]) -> Data? {
        
        return parameters.urlEncodedParametersData
    }
    
    open func urlRequest(from accessTokenRequest: AccessTokenRequest) -> URLRequest {
        
        var request = URLRequest(url: self.tokenEndpoint)
        request.httpMethod = "POST"
        request.httpBody = self.data(from: self.parameters(from: accessTokenRequest))
        
        return request
    }
    
    open func authorize(_ request: URLRequest, handler: @escaping (URLRequest, Error?) -> Void) {
        
        self.clientAuthorizer.authorize(request: request, handler: handler)
    }
    
    @available(iOS 13, tvOS 13.0.0, macOS 10.15, *)
    open func authorizeAsync(_ request: URLRequest) async throws -> URLRequest {
        
        return try await self.clientAuthorizer.authorizeAsync(request: request)
    }
    
    open func perform(_ request: URLRequest, completion: @escaping (NetworkResponse) -> Void) {
        
        self.networkClient.perform(request, completion: completion)
    }
    
    @available(iOS 13, tvOS 13.0.0, macOS 10.15, *)
    open func performAsync(_ request: URLRequest) async -> NetworkResponse {
        
        return await withCheckedContinuation { continuation in
            
            self.perform(request) { response in
                continuation.resume(returning: response)
            }
        }
    }
    
    open func accessTokenResponse(from networkResponse: NetworkResponse) throws -> AccessTokenResponse {
        
        return try AccessTokenResponseHandler().handle(response: networkResponse)
    }
    
    open func validate(_ accessTokenResponse: AccessTokenResponse) throws {
        
        //nothing to validate here
    }
    
    open func authenticate(using request: URLRequest, handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
        
        self.authorize(request, handler: { (request, error) in
            
            guard error == nil else {
                
                handler(nil, error)
                return
            }
            
            self.perform(request, completion: { (response) in
                
                do {
                    
                    let accessTokenResponse = try self.accessTokenResponse(from: response)
                    try self.validate(accessTokenResponse)
                    
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
    }
    
    @available(iOS 13, tvOS 13.0.0, macOS 10.15, *)
    open func authenticateAsync(using request: URLRequest) async throws -> AccessTokenResponse? {
         
        let urlRequest = try await self.authorizeAsync(request)
        let response = await self.performAsync(urlRequest)
        let accessTokenResponse = try self.accessTokenResponse(from: response)
        try self.validate(accessTokenResponse)
        return accessTokenResponse
    }
    
    //MARK: - AuthorizationGrantFlow
    
    open func authenticate(handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
        
        self.credentialsProvider.credentials { (username, password) in
            
            //build the request
            let accessTokenRequest = AccessTokenRequest(username: username, password: password, scope: self.scope)
            let request = self.urlRequest(from: accessTokenRequest)
            
            self.authenticate(using: request, handler: { (response, error) in
            
                if let error = error {
                    
                    self.credentialsProvider.didFailAuthenticating(with: error)
                }
                else {
                    
                    self.credentialsProvider.didFinishAuthenticating()
                }
                
                handler(response, error)
            })
        }
    }
    
    @available(iOS 13, tvOS 13.0.0, macOS 10.15, *)
    open func authenticateAsync() async throws -> AccessTokenResponse? {
        
        let credentials = await self.credentialsProvider.credentialsAsync()
        
        let username = credentials.0
        let password = credentials.1
        
        //build the request
        let accessTokenRequest = AccessTokenRequest(username: username, password: password, scope: self.scope)
        let request = self.urlRequest(from: accessTokenRequest)
        
        do {
            
            let response = try await self.authenticateAsync(using: request)
            self.credentialsProvider.didFinishAuthenticating()
            return response
        }
        catch {
            
            self.credentialsProvider.didFailAuthenticating(with: error)
            throw error
        }
    }
}

extension ResourceOwnerPasswordCredentialsGrantFlow {
    
    /**
     Creates an instance of the receiver.
     
     - parameter tokenEndpoint: The URL of the token endpoint
     - parameter credentialsProvider: A credentials provider used to retrieve username and password in order authenticate the client. This could be your login view controller for example.
     - parameter scope: The scope of the access request.
     - parameter clientID: The client id used to autheorize the authentication request.
     - parameter secret: The secret used to autheorize the authentication request.
     - parameter networkClient: A network client used to perform the authentication request.
     
     */
    
    public convenience init(tokenEndpoint: URL, credentialsProvider: CredentialsProvider, scope: Scope?, clientID: String, secret: String, networkClient: NetworkClient = _defaultNetworkClient) {
        
        let clientAuthorizer = HTTPBasicAuthorizer(clientID: clientID, secret: secret)
        
        self.init(tokenEndpoint: tokenEndpoint, credentialsProvider: credentialsProvider, scope: scope, clientAuthorizer: clientAuthorizer, networkClient: networkClient)
    }
    
    /**
     Creates an instance of the receiver.
     
     - parameter tokenEndpoint: The URL of the token endpoint
     - parameter username: The username used for authentication.
     - parameter password: The password used for authentication.
     - parameter scope: The scope of the access request.
     - parameter clientID: The client id used to autheorize the authentication request.
     - parameter secret: The secret used to autheorize the authentication request.
     - parameter networkClient: A network client used to perform the authentication request.
     
     - note: It is highly recommended to implement your own CredentialsProvider and use it instead of providing username and password directly. This way you could implement a loginc screen as a CredentialsProvider and allow the user to enter their username and password when needed.
     */
    
    public convenience init(tokenEndpoint: URL, username: String, password: String, scope: Scope?, clientID: String, secret: String, networkClient: NetworkClient = _defaultNetworkClient) {
        
        let credentialsProvider = AnyCredentialsProvider(username: username, password: password)
        let clientAuthorizer = HTTPBasicAuthorizer(clientID: clientID, secret: secret)
        
        self.init(tokenEndpoint: tokenEndpoint, credentialsProvider: credentialsProvider, scope: scope, clientAuthorizer: clientAuthorizer, networkClient: networkClient)
    }
    
    /**
     Creates an instance of the receiver.
     
     - parameter tokenEndpoint: The URL of the token endpoint
     - parameter username: The username used for authentication.
     - parameter password: The password used for authentication.
     - parameter scope: The scope of the access request.
     - parameter clientAuthorizer: An authorizer used to authorize the authentication request. Usually an instance of HTTPBasicAuthorizer with your clientID and secret.
     - parameter networkClient: A network client used to perform the authentication request.
     
     - note: It is highly recommended to implement your own CredentialsProvider and use it instead of providing username and password directly. This way you could implement a loginc screen as a CredentialsProvider and allow the user to enter their username and password when needed.
     */
    
    public convenience init(tokenEndpoint: URL, username: String, password: String, scope: Scope?, clientAuthorizer: RequestAuthorizer, networkClient: NetworkClient = _defaultNetworkClient) {
        
        let credentialsProvider = AnyCredentialsProvider(username: username, password: password)
        
        self.init(tokenEndpoint: tokenEndpoint, credentialsProvider: credentialsProvider, scope: scope, clientAuthorizer: clientAuthorizer, networkClient: networkClient)
    }
}


//MARK: - Models

extension ResourceOwnerPasswordCredentialsGrantFlow {
    
    //https://tools.ietf.org/html/rfc6749#section-4.3.2
    public struct AccessTokenRequest {
        
        public let grantType: GrantType = .password
        public var username: String
        public var password: String
        public var scope: Scope?
        
        public init(username: String, password: String, scope: Scope? = nil) {
            
            self.username = username
            self.password = password
            self.scope = scope
        }
        
        public var dictionary: [String: Any] {
            
            var dictionary = [String: Any]()
            dictionary["grant_type"] = self.grantType.rawValue
            dictionary["username"] = self.username
            dictionary["password"] = self.password
            dictionary["scope"] = self.scope?.value
            
            return dictionary
        }
    }
    
    
}
