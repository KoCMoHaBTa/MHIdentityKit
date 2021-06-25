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
    
    public func authorize(request: URLRequest) async throws -> URLRequest {
        
        guard let credentials = (username + ":" + password).data(using: .utf8)?.base64EncodedString() else {
            
            throw MHIdentityKitError.authorizationFailed(reason: MHIdentityKitError.Reason.buildAuthenticationHeaderFailed)
        }
        
        var request = request
        let header = "Basic " + credentials
        request.setValue(header, forHTTPHeaderField: "Authorization")
        return request
    }
}

extension HTTPBasicAuthorizer {
    
    public init(clientID: String, secret: String) {
        
        self.init(username: clientID, password: secret)
    }
}

extension RequestAuthorizer where Self == HTTPBasicAuthorizer {
    
    public static func basic(username: String, password: String) -> Self {
        
        .init(username: username, password: password)
    }
    
    public static func basic(clientID: String, secret: String) -> Self {
        
        .init(clientID: clientID, secret: secret)
    }
}
