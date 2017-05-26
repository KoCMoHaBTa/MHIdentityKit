//
//  RequestAuthorizer.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/25/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///A type that authorize instances of URLRequest
public protocol RequestAuthorizer {
    
    /**
     Authorizes an instance of URLRequest.
     
     Upon success, in the callback handler, the provided request will be authorized, otherwise the original request will be provided.
     
     - parameter request: The request to authorize.
     - parameter handler: The callback, executed when the authorization is complete. The callback takes 2 arguments - an URLRequest and an Error
     */
    func authorize(request: URLRequest, handler: @escaping (URLRequest, Error?) -> Void)
}

extension URLRequest {
    
    /**
     Authorize the receiver using a given authorizer. 
     
     Upon success, in the callback handler, the provided request will be an authorized copy of the receiver, otherwise a copy of the original receiver will be provided.
     
     - note: The implementation of this method simply calls `authorize` on the `authorizer`. For more information see `URLRequestAuthorizer`.
     
     - parameter authorizer: The authorizer used to authorize the receiver.
     - parameter handler: The callback, executed when the authorization is complete. The callback takes 2 arguments - an URLRequest and an Error
     
     */
    public func authorize(using authorizer: RequestAuthorizer, handler: @escaping (URLRequest, Error?) -> Void) {
        
        authorizer.authorize(request: self, handler: handler)
    }
}

//a potentual implementation would be one that sets client id and secret into URL as query parameters
//another one would be one that sets client id and secret as 



