//
//  ClientHTTPBasicAuthorizer.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/26/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///Authorizes a request using HTTP Basic authentication scheme
public struct HTTPBasicAuthorizer: RequestAuthorizer {
    
    public var username: String
    public var password: String
    
    public init(username: String, password: String) {
        
        self.username = username
        self.password = password
    }
    
    public func authorize(request: URLRequest, handler: @escaping (URLRequest, Error?) -> Void) {
        
        guard let credentials = (username + ":" + password).data(using: .utf8)?.base64EncodedString() else {
            
            let error = MHIdentityKitError.authorizationFailed(reason: MHIdentityKitError.Reason.buildAuthenticationHeaderFailed)
            handler(request, error)
            return
        }
        
        var request = request
        let header = "Basic " + credentials
        request.setValue(header, forHTTPHeaderField: "Authorization")
        handler(request, nil)
    }
    
    @available(iOS 13, tvOS 13.0.0, macOS 10.15, *)
    public func authorize(request: URLRequest) async throws -> URLRequest {
        return try await withCheckedThrowingContinuation { continuation in
            
            self.authorize(request: request) { (request, error) in
                
                if let error = error {
                    continuation.resume(throwing: error)
                }
                else {
                    continuation.resume(returning: request)
                }
            }
        }
    }
}

extension HTTPBasicAuthorizer {
    
    public init(clientID: String, secret: String) {
        
        self.init(username: clientID, password: secret)
    }
}
