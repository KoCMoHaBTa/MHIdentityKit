//
//  ClientHTTPBasicAuthorizer.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/26/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///Authorizes a request using HTTP Basic authentication scheme
public struct ClientHTTPBasicAuthorizer: RequestAuthorizer {
    
    public let clientID: String
    public let secret: String
    
    public func authorize(request: URLRequest, handler: @escaping (URLRequest, Error?) -> Void) {
        
        guard let client = (clientID + ":" + secret).data(using: .utf8)?.base64EncodedString() else {
            
            let error = MHIdentityKitError.authorizationFailed(reason: MHIdentityKitError.Reason.buildAuthenticationHeaderFailed)
            handler(request, error)
            return
        }
        
        var request = request
        let header = "Basic " + client
        request.setValue(header, forHTTPHeaderField: "Authorization")
        handler(request, nil)
    }
}
