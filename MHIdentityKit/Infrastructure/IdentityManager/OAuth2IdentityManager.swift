//
//  OAuth2IdentityManager.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 6/5/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///Perform an authorization using an OAuth2 AuthorizationGrantFlow for authentication with a behaviour that refresh a token if possible and preserves a state.
///The core logic is ilustrated here - https://tools.ietf.org/html/rfc6749#section-1.5
open class OAuth2IdentityManager: IdentityManager {
    
    //used for authentication - getting OAuth2 access token
    open let flow: AuthorizationGrantFlow
    
    //used to refresh an access token using a refresh token if aplicable
    open let refresher: AccessTokenRefresher?
    
    //used to store state, like the refresh token
    open let storage: IdentityStorage
    
    //used to provide an authorizer that authorize the request using the provided access token response
    open let tokenAuthorizerProvider: (AccessTokenResponse) -> RequestAuthorizer
    
    /**
     Creates an instnce of the receiver.
     
     - parameter flow: An OAuth2 authorization grant flow used for authentication.
     - parameter refresher: An optional access token refresher, used to refresh an access token if expired and when possible.
     - parameter storage: An identity storage, used to store some state, like the refresh token.
     - parameter tokenAuthorizerProvider: A closure that provides a request authorizer used to authorize incoming requests with the provided access token
     
     */
    
    public init(flow: AuthorizationGrantFlow, refresher: AccessTokenRefresher?, storage: IdentityStorage, tokenAuthorizerProvider: @escaping (AccessTokenResponse) -> RequestAuthorizer) {
        
        self.flow = flow
        self.refresher = refresher
        self.storage = storage
        self.tokenAuthorizerProvider = tokenAuthorizerProvider
    }
    
    //MARK: - Configuration
    
    ///Controls whenver an authorization should be forced if a refresh fails. If `true`, when a refresh token fails, an authentication will be performed automatically using the flow provided. If `false` an error will be returned. Default to `true`.
    open var forceAuthenticateOnRefreshError = true
    
    //MARK: - State
    
    private var accessTokenResponse: AccessTokenResponse?
    
    //MARK: - IdentityManager
    
    private func authenticate(forced: Bool, handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
        
        //force authenticate
        if forced {
            
            //authenticate
            self.flow.authenticate(handler: handler)
            return
        }
        
        //refresh if possible
        if let refreshToken = self.accessTokenResponse?.refreshToken {
            
            let request = AccessTokenRefreshRequest(refreshToken: refreshToken, scope: self.accessTokenResponse?.scope)
            self.refresher?.refresh(using: request, handler: { [weak self] (response, error) in
                
                //if force authentication is enabled upon refresh error
                if self?.forceAuthenticateOnRefreshError == true && error != nil {
                    
                    //authenticate
                    self?.flow.authenticate(handler: handler)
                    return
                }
                
                //complete
                handler(response, error)
            })
            
            return
        }

        //authenticate
        self.flow.authenticate(handler: handler)
    }
    
    open func authorize(request: URLRequest, forceAuthenticate: Bool = false, handler: @escaping (URLRequest, Error?) -> Void) {
        
        if forceAuthenticate == false, let response = self.accessTokenResponse, response.isExpired == false   {
            
            self.tokenAuthorizerProvider(response).authorize(request: request, handler: handler)
            return
        }
        
        self.authenticate(forced: forceAuthenticate) { (response, error) in
            
            self.accessTokenResponse = response
            
            guard
            error == nil,
            let response = response
            else {
                
                handler(request, error)
                return
            }
            
            self.tokenAuthorizerProvider(response).authorize(request: request, handler: handler)
        }
    }
}

extension OAuth2IdentityManager {
    
    /**
     Creates an instnce of the receiver when the access token is expected to be of a Bearer type with a specified authorization method.
     
     - parameter flow: An OAuth2 authorization grant flow used for authentication.
     - parameter refresher: An optional access token refresher, used to refresh an access token if expired and when possible.
     - parameter storage: An identity storage, used to store some state, like the refresh token.
     - parameter authorizationMethod: The authorization method used to authorize the requests. Default to `.header`
     
     */
    
    public convenience init(flow: AuthorizationGrantFlow, refresher: AccessTokenRefresher?, storage: IdentityStorage, authorizationMethod: BearerAccessTokenAuthorizer.AuthorizationMethod = .header) {
        
        let tokenAuthorizerProvider = { (response: AccessTokenResponse) -> RequestAuthorizer in
            
            return BearerAccessTokenAuthorizer(token: response.accessToken, method: authorizationMethod)
        }
        
        self.init(flow: flow, refresher: refresher, storage: storage, tokenAuthorizerProvider: tokenAuthorizerProvider)
    }
}
