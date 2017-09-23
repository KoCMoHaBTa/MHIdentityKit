//
//  ClientCredentialsGrantFlow.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 6/2/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

//https://tools.ietf.org/html/rfc6749#section-4.4
public class ClientCredentialsGrantFlow: AuthorizationGrantFlow {
    
    public let tokenEndpoint: URL
    public let scope: Scope?
    public let clientAuthorizer: RequestAuthorizer
    public let networkClient: NetworkClient
    
    /**
     Creates an instance of the receiver.
     
     - parameter tokenEndpoint: The URL of the token endpoint
     - parameter scope: The scope of the access request.
     - parameter clientAuthorizer: An authorizer used to authorize the authentication request. Usually an instance of HTTPBasicAuthorizer with your clientID and secret.
     - parameter networkClient: A network client used to perform the authentication request.
     
     */
    
    public init(tokenEndpoint: URL, scope: Scope? = nil, clientAuthorizer: RequestAuthorizer, networkClient: NetworkClient = _defaultNetworkClient) {
        
        self.tokenEndpoint = tokenEndpoint
        self.scope = scope
        self.clientAuthorizer = clientAuthorizer
        self.networkClient = networkClient
    }
    
    public func authenticate(handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
        
        //build the request
        var request = URLRequest(url: self.tokenEndpoint)
        request.httpMethod = "POST"
        request.httpBody = AccessTokenRequest(scope: self.scope).dictionary.urlEncodedParametersData
        
        self.authorizeAndPerform(request: request, using: self.clientAuthorizer, and: self.networkClient, handler: { (accessTokenResponse, error) in
            
            //https://tools.ietf.org/html/rfc6749#section-4.4.3
            //A refresh token SHOULD NOT be included
            guard accessTokenResponse?.refreshToken == nil else {
                
                let error = MHIdentityKitError.authenticationFailed(reason: MHIdentityKitError.Reason.invalidAccessTokenResponse)
                handler(nil, error)
                return
            }
            
            //any validation logic can go here
            handler(accessTokenResponse, error)
        })
    }
}

//MARK: - Models

extension ClientCredentialsGrantFlow {
    
    //https://tools.ietf.org/html/rfc6749#section-4.4.2
    fileprivate struct AccessTokenRequest {
        
        let grantType: GrantType = .clientCredentials
        let scope: Scope?
        
        var dictionary: [String: Any] {
            
            var dictionary = [String: Any]()
            dictionary["grant_type"] = self.grantType.rawValue
            dictionary["scope"] = self.scope?.value
            
            return dictionary
        }
    }
    
    
}
