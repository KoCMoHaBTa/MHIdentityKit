//
//  AccessTokenRefreshRequest.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 6/2/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

//https://tools.ietf.org/html/rfc6749#section-6
public struct AccessTokenRefreshRequest {
    
    public let grantType: GrantType = .refreshToken
    public var refreshToken: String
    public var scope: Scope?
    
    public init(refreshToken: String, scope: Scope?) {
        
        self.refreshToken = refreshToken
        self.scope = scope
    }
    
    public var dictionary: [String: Any] {
        
        var dictionary = [String: Any]()
        dictionary["grant_type"] = self.grantType.rawValue
        dictionary["refresh_token"] = self.refreshToken
        dictionary["scope"] = self.scope?.rawValue
        
        return dictionary
    }
}
