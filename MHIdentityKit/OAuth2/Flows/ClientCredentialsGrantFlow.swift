//
//  ClientCredentialsGrantFlow.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 6/2/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

//https://tools.ietf.org/html/rfc6749#section-4.4
open class ClientCredentialsGrantFlow: AuthorizationGrantFlow {
    
    public let tokenEndpoint: URL
    public let scope: Scope?
    public let clientAuthorizer: RequestAuthorizer
    public let networkClient: NetworkClient
    
    ///You can specify additional access token request parameters. If existing key is duplicated, the one specified by this property will be used.
    public var additionalAccessTokenRequestParameters: [String: Any] = [:]
    
    /**
     Creates an instance of the receiver.
     
     - parameter tokenEndpoint: The URL of the token endpoint
     - parameter scope: The scope of the access request.
     - parameter clientAuthorizer: An authorizer used to authorize the authentication request. Usually an instance of HTTPBasicAuthorizer with your clientID and secret.
     - parameter networkClient: A network client used to perform the authentication request.
     
     */
    
    public init(tokenEndpoint: URL, scope: Scope? = nil, clientAuthorizer: RequestAuthorizer, networkClient: NetworkClient = .default) {
        
        self.tokenEndpoint = tokenEndpoint
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
    
    
    open func authorize(_ request: URLRequest) async throws -> URLRequest {
        
        try await clientAuthorizer.authorize(request: request)
    }
    
    open func perform(_ request: URLRequest) async throws -> NetworkResponse {
        
        try await networkClient.perform(request)
    }
    
    open func accessTokenResponse(from networkResponse: NetworkResponse) throws -> AccessTokenResponse {
        
        try AccessTokenResponse(from: networkResponse)
    }
    
    open func validate(_ accessTokenResponse: AccessTokenResponse) async throws {
        
        //https://tools.ietf.org/html/rfc6749#section-4.4.3
        //A refresh token SHOULD NOT be included
        guard accessTokenResponse.refreshToken == nil else {
            
            throw MHIdentityKitError.authenticationFailed(reason: MHIdentityKitError.Reason.invalidAccessTokenResponse)
        }
    }
    
    open func authenticate(using request: URLRequest) async throws -> AccessTokenResponse {
        
        let request = try await authorize(request)
        let response = try await perform(request)
        let accessTokenResponse = try accessTokenResponse(from: response)
        try await validate(accessTokenResponse)
        return accessTokenResponse
    }
    
    //MARK: - AuthorizationGrantFlow
    
    open func authenticate() async throws -> AccessTokenResponse {
        
        //build the request
        let accessTokenRequest = AccessTokenRequest(scope: scope)
        let request = urlRequest(from: accessTokenRequest)
        return try await authenticate(using: request)
    }
}

//MARK: - Models

extension ClientCredentialsGrantFlow {
    
    //https://tools.ietf.org/html/rfc6749#section-4.4.2
    public struct AccessTokenRequest {
        
        public let grantType: GrantType = .clientCredentials
        public var scope: Scope?
        
        public init(scope: Scope? = nil) {
         
            self.scope = scope
        }
        
        public var dictionary: [String: Any] {
            
            var dictionary = [String: Any]()
            dictionary["grant_type"] = grantType.rawValue
            dictionary["scope"] = scope?.rawValue
            
            return dictionary
        }
    }
    
    
}
