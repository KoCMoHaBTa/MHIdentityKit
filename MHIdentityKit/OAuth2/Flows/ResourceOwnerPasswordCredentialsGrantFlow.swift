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
    
    ///Build the parameteres used for the [Access Token Request](https://tools.ietf.org/html/rfc6749#section-4.3.2)
    open func accessTokenRequestParameters(username: String, password: String) throws -> [String: Any] {
                
        var parameters = [String: Any]()
        parameters["grant_type"] = GrantType.password.rawValue
        parameters["username"] = username
        parameters["password"] = password
        parameters["scope"] = scope?.rawValue
        
        //merge with any additionally provided parameteres
        parameters.merge(additionalAccessTokenRequestParameters, uniquingKeysWith: { $1 })
        
        return parameters
    }
    
    ///Construct the [Access Token Request](https://tools.ietf.org/html/rfc6749#section-4.3.2) using the supplied parameters
    open func accessTokenRequest(withParameteres parameteres: [String: Any]) -> URLRequest {
        
        var request = URLRequest(url: tokenEndpoint)
        request.httpMethod = "POST"
        request.httpBody = parameteres.urlEncodedParametersData
        
        return request
    }
    
    open func validate(_ accessTokenResponse: AccessTokenResponse) async throws {
        
        //nothing to validate here
    }
    
    //MARK: - AuthorizationGrantFlow
    
    open func authenticate() async throws -> AccessTokenResponse {
        
        do {
            
            //get credentials
            let (username, password) = await credentialsProvider.credentials()
            
            //build & perform the request
            let accessTokenRequestParameters = try accessTokenRequestParameters(username: username, password: password)
            let accessTokenRequest = try await accessTokenRequest(withParameteres: accessTokenRequestParameters).authorized(using: clientAuthorizer)
            
            let accessTokenNetworkResponse = try await networkClient.perform(accessTokenRequest)
            let accessTokenResponse = try AccessTokenResponse(from: accessTokenNetworkResponse)
            
            try await validate(accessTokenResponse)
            
            //notify credentials provider about success
            credentialsProvider.didFinishAuthenticating()
            
            return accessTokenResponse
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
