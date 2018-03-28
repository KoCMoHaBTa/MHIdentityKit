//
//  AuthorizationResponseType.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 27.03.18.
//  Copyright © 2018 Milen Halachev. All rights reserved.
//

import Foundation

//https://tools.ietf.org/html/rfc6749#section-3.1.1
public struct AuthorizationResponseType  {
    
    public var value: String
    
    public init(value: String) {
        
        self.value = value
    }
}

//predefined grant types
extension AuthorizationResponseType {
    
    public static let code: AuthorizationResponseType = "code"
    public static let token: AuthorizationResponseType = "token"
}

//MARK: - RawRepresentable
extension AuthorizationResponseType: RawRepresentable {
    
    public var rawValue: String {
        
        get { return self.value }
        set { self.value = newValue }
    }
    
    public init?(rawValue: String) {
        
        self.init(value: rawValue)
    }
}

//MARK: - ExpressibleByStringLiteral
extension AuthorizationResponseType: ExpressibleByStringLiteral {
    
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
extension AuthorizationResponseType: CustomStringConvertible {
    
    public var description: String {
        
        return self.value
    }
}
