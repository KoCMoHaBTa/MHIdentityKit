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
    
    ///Clears any authentication state, leading to next authorization to require authentication. (eg Logout)
    func revokeAuthenticationState()
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
    
    ///Performs forced authentication on a placeholder request. Can be used when you want to authenticate in advance, without authorizing a particular request
    public func forceAuthenticate(handler: ((Error?) -> Void)?) {
        
        let placeholderURL = URL(string: "http://foo.bar")!
        let placeholderRequest = URLRequest(url: placeholderURL)
        
        self.authorize(request: placeholderRequest, forceAuthenticate: true) { (_, error) in
            
            handler?(error)
        }
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
