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

extension RequestAuthorizer {
    
    @available(iOS 13, tvOS 13.0.0, macOS 10.15, *)
    func authorize(request: URLRequest) async throws -> URLRequest {
        
        return try await withCheckedThrowingContinuation { continuation in
            
            self.authorize(request: request) { urlRequest, error in
                
                if let error = error {
                    continuation.resume(throwing: error)
                }
                else {
                    continuation.resume(returning: urlRequest)
                }
            }
        }
    }
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
    
    @available(iOS 13, tvOS 13.0.0, macOS 10.15, *)
    public func authorize(using authorizer: RequestAuthorizer) async throws -> URLRequest {
        
        return try await authorizer.authorize(request: self)
    }
    
    /**
     Synchronously authorize the receiver using a given authorizer.
     
     - warning: This method could potentially perform a network request synchrnously. Because of this it is hihgly recommended to NOT use this method from the main thread.
     
     - parameter authorizer: The authorizer used to authorize the receiver.
     
     - throws: An authorization error.
     - returns: An authorized copy of the recevier.
     */
    public func authorized(using authorizer: RequestAuthorizer) throws -> URLRequest {
        
        var request = self
        var error: Error? = nil
        
        let semaphore = DispatchSemaphore(value: 0)
        
        DispatchQueue(label: bundleIdentifier + ".authorization", qos: .default).async {
            
            self.authorize(using: authorizer, handler: { (r, e) in
                
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
     Synchronously authorize the receiver using a given authorizer.
     
     - warning: This method could potentially perform a network request synchrnously. Because of this it is hihgly recommended to NOT use this method from the main thread.
     
     - parameter authorizer: The authorizer used to authorize the receiver.
     
     - throws: An authorization error.
     */
    
    public mutating func authorize(using authorizer: RequestAuthorizer) throws {
        
        try self = self.authorized(using: authorizer)
    }
}

//a potentual implementation would be one that sets client id and secret into URL as query parameters
//another one would be one that sets client id and secret as 



