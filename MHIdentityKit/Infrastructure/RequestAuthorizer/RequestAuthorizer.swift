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
     - throws: Error if the request cannot be authorized.
     - returns: An authorized copy of the request.
     */
    func authorize(request: URLRequest) async throws -> URLRequest
}

extension URLRequest {
    
    /**
     Authorize the receiver using a given authorizer.
     
     - parameter authorizer: The authorizer used to authorize the receiver.
     - throws: An error, if the authorized cannot authorize the request.
     - returns: An authorized copy of the recevier.
     */
    public func authorized(using authorizer: RequestAuthorizer) async throws -> URLRequest {
        
        try await authorizer.authorize(request: self)
    }
    
    /**
     Authorize the receiver using a given authorizer.
     
     - parameter authorizer: The authorizer used to authorize the receiver.
     - throws: An error, if the authorized cannot authorize the request..
     */
    
    public mutating func authorize(using authorizer: RequestAuthorizer) async throws {
        
        self = try await authorized(using: authorizer)
    }
}

//a potentual implementation would be one that sets client id and secret into URL as query parameters
//another one would be one that sets client id and secret as 



