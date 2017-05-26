//
//  AccessTokenAuthorizer.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/26/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///Authorizes a request using
public struct AccessTokenAuthorizer: RequestAuthorizer {
    
    public let token: String
    public let tokenType: String
    
    public func authorize(request: URLRequest, handler: @escaping (URLRequest, Error?) -> Void) {
        
    }
}
