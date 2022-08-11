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
     
     Upon success, in the callback handler, the provided request will be authorized, otherwise the original request will be provided.
     
     - parameter request: The request to authorize.
     - parameter forceAuthenticate: If true, an authentication is always performed, otherwise authentication is done only if internal state requires it, like the access token has expired
     - parameter handler: The callback, executed when the authorization is complete. The callback takes 2 arguments - an URLRequest and an Error
     */
    
    func authorize(request: URLRequest, forceAuthenticate: Bool, handler: @escaping (URLRequest, Error?) -> Void)
    
    @available(iOS 13, *)
    func authorizeAsync(request: URLRequest, forceAuthenticate: Bool) async throws -> URLRequest
    
    ///Clears any authentication state, leading to next authorization to require authentication. (eg Logout)
    func revokeAuthenticationState()
    
    ///Clears any authorization state, leading to next authorization to require refresh or authentication. (eg revoke the access token only)
    func revokeAuthorizationState()
    
    ///Validates a network response based on whenever it requires authorization or not. Returns true if the response is valid and does not require authorization, otherwise return false. Default implementation checks whenever the HTTP status code != 401 for a valid response.
    var responseValidator: NetworkResponseValidator { get }
}

extension IdentityManager {
    
    /**
     Authorizes an instance of URLRequest.
     
     Upon success, in the callback handler, the provided request will be authorized, otherwise the original request will be provided.
     
     - parameter request: The request to authorize.
     - parameter handler: The callback, executed when the authorization is complete. The callback takes 2 arguments - an URLRequest and an Error
     */
    
    public func authorize(request: URLRequest, handler: @escaping (URLRequest, Error?) -> Void) {
        
        self.authorize(request: request, forceAuthenticate: false, handler: handler)
    }
    
    @available(iOS 13, *)
    public func authorizeAsync(request: URLRequest) async throws -> URLRequest {
        
        return try await self.authorizeAsync(request: request, forceAuthenticate: false)
    }
    
    ///Performs forced authentication on a placeholder request. Can be used when you want to authenticate in advance, without authorizing a particular request
    public func forceAuthenticate(handler: ((Error?) -> Void)? = nil) {
        
        let placeholderURL = URL(string: "http://foo.bar")!
        let placeholderRequest = URLRequest(url: placeholderURL)
        
        self.authorize(request: placeholderRequest, forceAuthenticate: true) { (_, error) in
            
            handler?(error)
        }
    }
    
    @available(iOS 13, *)
    public func forceAuthenticateAsync() async throws {
        
        let placeholderURL = URL(string: "http://foo.bar")!
        let placeholderRequest = URLRequest(url: placeholderURL)
        _ = try await self.authorizeAsync(request: placeholderRequest, forceAuthenticate: true)
    }
}

extension URLRequest {
    
    /**
     Authorize the receiver using a given identity manager.
     
     Upon success, in the callback handler, the provided request will be an authorized copy of the receiver, otherwise a copy of the original receiver will be provided.
     
     - note: The implementation of this method simply calls `authorize` on the `authorizer`. For more information see `URLRequestAuthorizer`.
     
     - parameter authorizer: The authorizer used to authorize the receiver.
     - parameter handler: The callback, executed when the authorization is complete. The callback takes 2 arguments - an URLRequest and an Error
     
     */
    public func authorize(using identityManager: IdentityManager, forceAuthenticate: Bool = false, handler: @escaping (URLRequest, Error?) -> Void) {
        
        identityManager.authorize(request: self, forceAuthenticate: forceAuthenticate, handler: handler)
    }
    
    /**
     Synchronously authorize the receiver using a given identity manager.
     
     - warning: This method could potentially perform a network request synchrnously. Because of this it is hihgly recommended to NOT use this method from the main thread.
     
     - parameter authorizer: The authorizer used to authorize the receiver.
     
     - throws: An authorization error.
     - returns: An authorized copy of the recevier.
     */
    public func authorized(using identityManager: IdentityManager, forceAuthenticate: Bool = false) throws -> URLRequest {
        
        var request = self
        var error: Error? = nil
        
        let semaphore = DispatchSemaphore(value: 0)
        
        DispatchQueue(label: bundleIdentifier + ".authorization", qos: .default).async {
            
            self.authorize(using: identityManager, forceAuthenticate: forceAuthenticate, handler: { (r, e) in
                
                request = r
                error = e
                
                semaphore.signal()
            })
        }
        
        semaphore.wait()
        
        guard error == nil else {
            
            throw error!
        }
        
        return request
    }
    
    /**
     Synchronously authorize the receiver using a given identity manager.
     
     - warning: This method could potentially perform a network request synchrnously. Because of this it is hihgly recommended to NOT use this method from the main thread.
     
     - parameter authorizer: The authorizer used to authorize the receiver.
     
     - throws: An authorization error.
     */
    
    public mutating func authorize(using identityManager: IdentityManager, forceAuthenticate: Bool = false) throws {
        
        try self = self.authorized(using: identityManager, forceAuthenticate: forceAuthenticate)
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
     - parameter completion: The completion handler called when the request completes.
     
     - note: The implementation of this menthod, simple checks if the HTTP response status code is 401 Unauthorized and if so - authorizes the request again by forcing the authentication. Then the request is retried.
     */
    
    public func perform(_ request: URLRequest, using networkClient: NetworkClient = _defaultNetworkClient, retryAttempts: Int = 1, validator: NetworkResponseValidator? = nil, forceAuthenticate: Bool = false, completion: @escaping (NetworkResponse) -> Void) {
        
        self.authorize(request: request, forceAuthenticate: forceAuthenticate) { (request, error) in
            
            guard error == nil else {
                
                completion(NetworkResponse(data: nil, response: nil, error: error))
                return
            }
            
            networkClient.perform(request) { (response) in
                
                let validator = validator ?? self.responseValidator
                if validator.validate(response) == false && retryAttempts > 0 {
                    
                    self.perform(request, using: networkClient, retryAttempts: retryAttempts - 1, validator: validator, forceAuthenticate: true, completion: completion)
                    return
                }
                
                completion(response)
            }
        }
    }
    
    @available(iOS 13, *)
    public func performAsync(_ request: URLRequest, using networkClient: NetworkClient = _defaultNetworkClient, retryAttempts: Int = 1, validator: NetworkResponseValidator? = nil, forceAuthenticate: Bool = false) async throws -> NetworkResponse {
        
        return await withCheckedContinuation { continuation in
            
            self.perform(request, using: networkClient, retryAttempts: retryAttempts, validator: validator, forceAuthenticate: forceAuthenticate) { response in
                continuation.resume(returning: response)
            }
        }
    }
}

