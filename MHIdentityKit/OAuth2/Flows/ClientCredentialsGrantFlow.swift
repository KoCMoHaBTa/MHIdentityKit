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
    
    ///Build the parameteres used for the [Access Token Request](https://tools.ietf.org/html/rfc6749#section-4.4.2)
    open func accessTokenRequestParameters() throws -> [String: Any] {
                
        var parameters = [String: Any]()
        parameters["grant_type"] = GrantType.clientCredentials.rawValue
        parameters["scope"] = scope?.rawValue
        
        //merge with any additionally provided parameteres
        parameters.merge(additionalAccessTokenRequestParameters, uniquingKeysWith: { $1 })
        
        return parameters
    }
    
    ///Construct the [Access Token Request](https://tools.ietf.org/html/rfc6749#section-4.4.2) using the supplied parameters
    open func accessTokenRequest(withParameteres parameteres: [String: Any]) -> URLRequest {
        
        var request = URLRequest(url: tokenEndpoint)
        request.httpMethod = "POST"
        request.httpBody = parameteres.urlEncodedParametersData
        
        return request
    }
    
    open func validate(_ accessTokenResponse: AccessTokenResponse) async throws {
        
        //https://tools.ietf.org/html/rfc6749#section-4.4.3
        //A refresh token SHOULD NOT be included
        guard accessTokenResponse.refreshToken == nil else {
            
            throw Error.accessTokenResponseContainsRefreshToken
        }
    }

    //MARK: - AuthorizationGrantFlow
    
    open func authenticate() async throws -> AccessTokenResponse {
        
        //build the request
        let accessTokenRequestParameters = try accessTokenRequestParameters()
        let accessTokenRequest = try await accessTokenRequest(withParameteres: accessTokenRequestParameters).authorized(using: clientAuthorizer)
        
        //perform the request
        let accessTokenNetworkResponse = try await networkClient.perform(accessTokenRequest)
        let accessTokenResponse = try AccessTokenResponse(from: accessTokenNetworkResponse)
        
        //validate the response
        try await validate(accessTokenResponse)
        
        return accessTokenResponse
    }
}

extension ClientCredentialsGrantFlow {
    
    enum Error: Swift.Error {
        
        ///Indicates that the access token response contains a refresh token. This [ClientCredentialsGrantFlow](https://tools.ietf.org/html/rfc6749#section-4.4.3) does not allow refresh tokens.
        case accessTokenResponseContainsRefreshToken
    }
}
