//
//  GrantType.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/25/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

public struct GrantType  {
    
    public var value: String
    
    public init(value: String) {
        
        self.value = value
    }
}

//predefined grant types
extension GrantType {
    
    public static let password: GrantType = "password"
    public static let refreshToken: GrantType = "refresh_token"
    public static let clientCredentials: GrantType = "client_credentials"
    public static let authorizationCode: GrantType = "authorization_code"
}

//MARK: - RawRepresentable
extension GrantType: RawRepresentable {
    
    public var rawValue: String {
        
        get { return self.value }
        set { self.value = newValue }
    }
    
    public init?(rawValue: String) {
        
        self.init(value: rawValue)
    }
}

//MARK: - ExpressibleByStringLiteral
extension GrantType: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        
        self.init(value: value)
    }
    
    public init(unicodeScalarLiteral value: String) {
        
        self.init(value: value)
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        
        self.init(value: value)
    }
}

//MARK: - CustomStringConvertible
extension GrantType: CustomStringConvertible {
    
    public var description: String {
        
        return self.value
    }
}
