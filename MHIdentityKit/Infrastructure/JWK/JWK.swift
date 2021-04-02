//
//  JWKS.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 2.04.21.
//  Copyright © 2021 Milen Halachev. All rights reserved.
//

import Foundation

/// https://tools.ietf.org/html/draft-ietf-jose-json-web-key-41#section-4
public struct JWK {
        
    public var parameters: [ParameterKey: Any]
    
    public init(data: Data) throws {
        
        guard let parameters = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            
            throw Error.unableToParseJWK
        }
        
        try self.init(parameters: parameters)
    }
    
    public init(parameters: [String: Any]) throws {
        
        try self.init(parameters: parameters.reduce(into: [:], { $0[.init(rawValue: $1.key)] = $1.value }))
    }
 
    public init(parameters: [ParameterKey: Any]) throws {
        
        guard let _ = parameters[.kty] as? String else {
            
            throw Error.invalidJWK(.missingParameter(.kty))
        }
        
        guard let _ = parameters[.kty] as? String else {
            
            throw Error.invalidJWK(.missingParameter(.kty))
        }
        
        self.parameters = parameters
    }
    
    #warning("Copy docs here")
    var kty: String { parameters[.kty] as! String }
    var use: String? { parameters[.use] as? String }
    var key_ops: [String]? { parameters[.key_ops] as? [String] }
    var alg: String? { parameters[.alg] as? String }
    var kid: String? { parameters[.kid] as? String }
    var x5u: String? { parameters[.x5u] as? String }
    var x5c: [String]? { parameters[.x5c] as? [String] }
    var x5t: String? { parameters[.x5t] as? String }
    var x5tS256: String? { parameters[.x5tS256] as? String }
}

extension JWK {
    
    public struct ParameterKey: RawRepresentable, Hashable, ExpressibleByStringLiteral {
        
        public var rawValue: String
        
        public init(rawValue: String) {
            
            self.rawValue = rawValue
        }
        
        public init(stringLiteral value: StringLiteralType) {
            
            self.init(rawValue: value)
        }
    }
}

extension JWK.ParameterKey {
    
    public static let kty: Self = "kty"
    public static let use: Self = "use"
    public static let key_ops: Self = "key_ops"
    public static let alg: Self = "alg"
    public static let kid: Self = "kid"
    public static let x5u: Self = "x5u"
    public static let x5c: Self = "x5c"
    public static let x5t: Self = "x5t"
    public static let x5tS256: Self = "x5t#S256"
    
}

extension JWK {
    
    public enum Error: Swift.Error {
        
        case unableToParseJWK
        case invalidJWK(Reason)
        
        public enum Reason: Swift.Error {
            
            case missingParameter(ParameterKey)
        }
    }
}
