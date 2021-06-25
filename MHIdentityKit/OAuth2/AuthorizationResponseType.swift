//
//  AuthorizationResponseType.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 27.03.18.
//  Copyright © 2018 Milen Halachev. All rights reserved.
//

import Foundation

//https://tools.ietf.org/html/rfc6749#section-3.1.1
public struct AuthorizationResponseType: RawRepresentable, ExpressibleByStringLiteral, CustomStringConvertible  {
    
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
extension AuthorizationResponseType {
    
    public static let code: AuthorizationResponseType = "code"
    public static let token: AuthorizationResponseType = "token"
}
