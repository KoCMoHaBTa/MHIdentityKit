//
//  GrantType.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/25/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

public struct GrantType: RawRepresentable, ExpressibleByStringLiteral, CustomStringConvertible  {
    
    public var rawValue: String
    
    public init(rawValue: String) {
        
        self.rawValue = rawValue
    }
    
    public init(stringLiteral value: String) {
        
        self.init(rawValue: value)
    }
    
    public var description: String { rawValue }
}

//predefined grant types
extension GrantType {
    
    public static let password: GrantType = "password"
    public static let refreshToken: GrantType = "refresh_token"
    public static let clientCredentials: GrantType = "client_credentials"
    public static let authorizationCode: GrantType = "authorization_code"
}
