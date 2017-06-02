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
    public let networkClient: NetworkClient
    public let clientAuthorizer: RequestAuthorizer
    
    public init(tokenEndpoint: URL, scope: Scope? = nil, networkClient: NetworkClient = DefaultNetoworkClient(), clientAuthorizer: RequestAuthorizer) {
        
        self.tokenEndpoint = tokenEndpoint
        self.scope = scope
        self.networkClient = networkClient
        self.clientAuthorizer = clientAuthorizer
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
                
                handler(nil, MHIdentityKitError.authenticationFailed(reason: MHIdentityKitError.Reason.invalidAccessTokenResponse))
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
