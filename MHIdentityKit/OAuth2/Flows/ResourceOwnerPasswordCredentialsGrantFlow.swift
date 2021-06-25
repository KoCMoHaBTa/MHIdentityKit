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
    
    public init(tokenEndpoint: URL, credentialsProvider: CredentialsProvider, scope: Scope?, clientAuthorizer: RequestAuthorizer, networkClient: NetworkClient = .default) {
        
        self.tokenEndpoint = tokenEndpoint
        self.credentialsProvider = credentialsProvider
        self.scope = scope
        self.clientAuthorizer = clientAuthorizer
        self.networkClient = networkClient
    }
    
    //MARK: - Flow logic
    
    open func parameters(from accessTokenRequest: AccessTokenRequest) -> [String: Any] {
        
        accessTokenRequest.dictionary.merging(self.additionalAccessTokenRequestParameters, uniquingKeysWith: { $1 })
    }
    
    open func data(from parameters: [String: Any]) -> Data? {
        
        parameters.urlEncodedParametersData
    }
    
    open func urlRequest(from accessTokenRequest: AccessTokenRequest) -> URLRequest {
        
        var request = URLRequest(url: tokenEndpoint)
        request.httpMethod = "POST"
        request.httpBody = data(from: parameters(from: accessTokenRequest))
        
        return request
    }
    
    open func authorize(_ request: URLRequest) async throws -> URLRequest {
        
        try await clientAuthorizer.authorize(request: request)
    }
    
    open func perform(_ request: URLRequest) async throws -> NetworkResponse {
        
        try await networkClient.perform(request)
    }
    
    open func accessTokenResponse(from networkResponse: NetworkResponse) throws -> AccessTokenResponse {
        
        try AccessTokenResponseHandler().handle(response: networkResponse)
    }
    
    open func validate(_ accessTokenResponse: AccessTokenResponse) async throws {
        
        //nothing to validate here
    }
    
    open func authenticate(using request: URLRequest) async throws -> AccessTokenResponse {
        
        let request = try await authorize(request)
        let netoworkRessponse = try await perform(request)
        let accessTokenResponse = try accessTokenResponse(from: netoworkRessponse)
        try await validate(accessTokenResponse)
         
        return accessTokenResponse
    }
    
    //MARK: - AuthorizationGrantFlow
    
    open func authenticate() async throws -> AccessTokenResponse {
        
        do {
            
            //get credentials
            let (username, password) = await credentialsProvider.credentials()
            
            //build & perform the request
            let accessTokenRequest = AccessTokenRequest(username: username, password: password, scope: scope)
            let request = urlRequest(from: accessTokenRequest)
            let response = try await authenticate(using: request)
            
            //notify credentials provider about success
            credentialsProvider.didFinishAuthenticating()
            
            return response
        }
        catch {
            
            //notify credentials provider about failure
            credentialsProvider.didFailAuthenticating(with: error)
            
            //rethrow the error
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
    
    public convenience init(tokenEndpoint: URL, credentialsProvider: CredentialsProvider, scope: Scope?, clientID: String, secret: String, networkClient: NetworkClient = .default) {
        
        self.init(
            tokenEndpoint: tokenEndpoint,
            credentialsProvider: credentialsProvider,
            scope: scope,
            clientAuthorizer: .basic(clientID: clientID, secret: secret),
            networkClient: networkClient
        )
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
    
    public convenience init(tokenEndpoint: URL, username: String, password: String, scope: Scope?, clientID: String, secret: String, networkClient: NetworkClient = .default) {
        
        let credentialsProvider = AnyCredentialsProvider(username: username, password: password)
        
        self.init(
            tokenEndpoint: tokenEndpoint,
            credentialsProvider: credentialsProvider,
            scope: scope,
            clientAuthorizer: .basic(clientID: clientID, secret: secret),
            networkClient: networkClient
        )
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
    
    public convenience init(tokenEndpoint: URL, username: String, password: String, scope: Scope?, clientAuthorizer: RequestAuthorizer, networkClient: NetworkClient = .default) {
        
        let credentialsProvider = AnyCredentialsProvider(username: username, password: password)
        
        self.init(
            tokenEndpoint: tokenEndpoint,
            credentialsProvider: credentialsProvider,
            scope: scope,
            clientAuthorizer: clientAuthorizer,
            networkClient: networkClient
        )
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
            dictionary["grant_type"] = grantType.rawValue
            dictionary["username"] = username
            dictionary["password"] = password
            dictionary["scope"] = scope?.rawValue
            
            return dictionary
        }
    }
    
    
}
