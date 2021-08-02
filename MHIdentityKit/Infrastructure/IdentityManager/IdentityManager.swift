//
//  IdentityManager.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 6/5/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///A type that manage authorization and authentication state and logic in order to perform easy to use authorization flow
///The goal of this type is to be a facade that hides the complexity of the OAuth2 flows and state management
public protocol IdentityManager {
    
    /**
     Authorizes an instance of URLRequest.
     
     - parameter request: The request to authorize.
     - parameter forceAuthenticate: If true, an authentication is always performed, otherwise authentication is done only if internal state requires it, like the access token has expired
     - throws: Error if authorization fails.
     - returns: An authorized copy of the request.
     */
    
    func authorize(request: URLRequest, forceAuthenticate: Bool) async throws -> URLRequest
    
    ///Clears any authentication state, leading to next authorization to require authentication. (eg Logout)
    func revokeAuthenticationState() async
    
    ///Clears any authorization state, leading to next authorization to require refresh or authentication. (eg revoke the access token only)
    func revokeAuthorizationState() async
    
    ///Validates a network response based on whenever it requires authorization or not. Returns true if the response is valid and does not require authorization, otherwise return false. Default implementation checks whenever the HTTP status code != 401 for a valid response.
    var responseValidator: NetworkResponseValidator { get }
}

extension IdentityManager {
    
    /**
     Authorizes an instance of URLRequest.
     
     - parameter request: The request to authorize.
     - throws: Error if authorization fails.
     - returns: An authorized copy of the request.
     */
    
    public func authorize(request: URLRequest) async throws -> URLRequest {
        
        try await authorize(request: request, forceAuthenticate: false)
    }
    
    ///Performs forced authentication on a placeholder request. Can be used when you want to authenticate in advance, without authorizing a particular request
    public func forceAuthenticate() async throws {
        
        let placeholderURL = URL(string: "http://foo.bar")!
        let placeholderRequest = URLRequest(url: placeholderURL)
        
        _ = try await authorize(request: placeholderRequest, forceAuthenticate: true)
    }
}

extension URLRequest {
    
    /**
     Authorize the receiver using a given identity manager.
     
     - note: The implementation of this method simply calls `authorize` on the `authorizer`. For more information see `URLRequestAuthorizer`.
     
     - parameter authorizer: The authorizer used to authorize the receiver.
     - throws: Error if authorization fails.
     - returns: An authorized copy of the receiver.
     
     */
    public func authorize(using identityManager: IdentityManager, forceAuthenticate: Bool = false) async throws -> URLRequest {
        
        try await identityManager.authorize(request: self, forceAuthenticate: forceAuthenticate)
    }
    
    /**
     Authorize the receiver using a given identity manager.
     
     - parameter authorizer: The authorizer used to authorize the receiver.
     - throws: An authorization error.
     */
    
    public mutating func authorize(using identityManager: IdentityManager, forceAuthenticate: Bool = false) async throws {
        
        self = try await self.authorize(using: identityManager, forceAuthenticate: forceAuthenticate)
    }
}

extension IdentityManager {
    
    public var responseValidator: NetworkResponseValidator {
        
        return AnyNetworkResponseValidator(handler: { (response) -> Bool in
            
            return (response.response as? HTTPURLResponse)?.statusCode != 401
        })
    }
    
    /**
     Performs a request and validates if the response requires authentication.
     
     - parameter request: The request to be performed
     - parameter networkClient: The client that should perform the request. Default to internal system client.
     - parameter retryAttempts: The number of times to retry the request if the validation fails.
     - parameter validator: The validator, used to determine if a request must be reauthorized with forced authentication and retried, based on the network response. Default to `responseValidator` if nil is passed.
     - parameter forceAuthenticate: Whenver to force authentication during authorization. Default to false.
     - throws: Error if network request fails.
     - returns: The network response of the  performed request.
     
     - note: The implementation of this menthod, simple checks if the HTTP response status code is 401 Unauthorized and if so - authorizes the request again by forcing the authentication. Then the request is retried.
     */
    
    public func perform(_ request: URLRequest, using networkClient: NetworkClient = .default, retryAttempts: Int = 1, validator: NetworkResponseValidator? = nil, forceAuthenticate: Bool = false) async throws -> NetworkResponse {
        
        let request = try await authorize(request: request, forceAuthenticate: forceAuthenticate)
        let response = try await networkClient.perform(request)
        let validator = validator ?? responseValidator
        
        if validator.validate(response) == false && retryAttempts > 0 {
            
            return try await perform(request, using: networkClient, retryAttempts: retryAttempts - 1, validator: validator, forceAuthenticate: true)
        }
        
        return response
    }
}

