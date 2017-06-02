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
public class ResourceOwnerPasswordCredentialsGrantFlow: AuthorizationGrantFlow {
    
    public let tokenEndpoint: URL
    public let credentialsProvider: CredentialsProvider
    public let scope: Scope?
    public let networkClient: NetworkClient
    public let clientAuthorizer: RequestAuthorizer

    //MARK: - Init
    
    public init(tokenEndpoint: URL, credentialsProvider: CredentialsProvider, scope: Scope? = nil, networkClient: NetworkClient = DefaultNetoworkClient(), clientAuthorizer: RequestAuthorizer) {
        
        self.tokenEndpoint = tokenEndpoint
        self.credentialsProvider = credentialsProvider
        self.scope = scope
        
        self.networkClient = networkClient
        self.clientAuthorizer = clientAuthorizer
    }
    
//    public convenience init(tokenEndpoint: URL, clientID: String, secret: String, username: String, password: String, scope: Scope? = nil) {
//        
//        self.init(tokenEndpoint: tokenEndpoint, credentialsProvider: DefaultCredentialsProvider(username: username, password: password), scope: scope, clientAuthorizer: ClientHTTPBasicAuthorizer(clientID: clientID, secret: secret))
//    }
    
    //MARK: - AuthorizationGrantFlow
    
    public func authenticate(handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
        
        self.credentialsProvider.credentials { [unowned self] (username, password) in
            
            //build the request
            var request = URLRequest(url: self.tokenEndpoint)
            request.httpMethod = "POST"
            request.httpBody = AccessTokenRequest(username: username, password: password, scope: self.scope).dictionary.urlEncodedParametersData
            
            self.authorizeAndPerform(request: request, using: self.clientAuthorizer, and: self.networkClient, handler: { (accessTokenResponse, error) in
                
                //any validation logic can go here
                handler(accessTokenResponse, error)
            })
        }
    }
}



//MARK: - Models

extension ResourceOwnerPasswordCredentialsGrantFlow {
    
    //https://tools.ietf.org/html/rfc6749#section-4.3.2
    fileprivate struct AccessTokenRequest {
        
        let grantType: GrantType = .password
        let username: String
        let password: String
        let scope: Scope?
        
        var dictionary: [String: Any] {
            
            var dictionary = [String: Any]()
            dictionary["grant_type"] = self.grantType.rawValue
            dictionary["username"] = self.username
            dictionary["password"] = self.password
            dictionary["scope"] = self.scope?.value
            
            return dictionary
        }
    }
    
    
}
