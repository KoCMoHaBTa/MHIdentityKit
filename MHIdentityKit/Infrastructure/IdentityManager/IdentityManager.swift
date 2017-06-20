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
    public func forceAuthenticate(handler: @escaping (Error?) -> Void) {
        
        let placeholderURL = URL(string: "http://foo.bar")!
        let placeholderRequest = URLRequest(url: placeholderURL)
        
        self.authorize(request: placeholderRequest, forceAuthenticate: true) { (_, error) in
            
            handler(error)
        }
    }
}
