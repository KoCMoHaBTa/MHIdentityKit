//
//  JWTType.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 19.07.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation

public enum JWTType {
    
    //https://tools.ietf.org/html/rfc7515
    case JWS //json web signature
    
    //https://tools.ietf.org/html/rfc7516
    case JWE //json web encryption
}

extension JWTType {
    
    //
    ///Tries to determine the type of a given JWT value, based on [Section 9](https://tools.ietf.org/html/draft-ietf-jose-json-web-encryption-40#section-9) of the JWE specification
    ///- note: OpenID Connect is using only the JWS/JWE Compact Serialization
    public init?(jwt value: String) {
        
        let segments = value.components(separatedBy: ".").count
        
        switch segments {
            case 3:
                self = .JWS
            
            case 5:
                self = .JWE
            
            default:
                return nil
        }
    }
}
