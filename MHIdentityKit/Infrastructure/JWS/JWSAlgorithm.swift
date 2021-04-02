//
//  JWSAlgorithm.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 26.08.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation

/*
 
 https://tools.ietf.org/html/rfc7518#section-3.1
 
 | HS256        | HMAC using SHA-256                | Required       |   Implemented as HS256SignatureVerifier
 | HS384        | HMAC using SHA-384                | Optional       |
 | HS512        | HMAC using SHA-512                | Optional       |
 | RS256        | RSASSA-PKCS-v1_5 using SHA-256    | Recommended    |   Implemented as RS256SignatureVerifier
 | RS384        | RSASSA-PKCS-v1_5 using SHA-384    | Optional       |
 | RS512        | RSASSA-PKCS-v1_5 using SHA-512    | Optional       |
 | ES256        | ECDSA using P-256 and SHA-256     | Recommended+   |   
 | ES384        | ECDSA using P-384 and SHA-384     | Optional       |
 | ES512        | ECDSA using P-521 and SHA-512     | Optional       |
 | PS256        | RSASSA-PSS using SHA-256 and MGF1 | Optional       |
 |              | with SHA-256                      |                |
 | PS384        | RSASSA-PSS using SHA-384 and MGF1 | Optional       |
 |              | with SHA-384                      |                |
 | PS512        | RSASSA-PSS using SHA-512 and MGF1 | Optional       |
 |              | with SHA-512                      |                |
 | none         | No digital signature or MAC       | Optional       |
 
 */

#warning("How to dynamically load a SignatureVerifier based on algorithm. Looks like we can't do it from here")
#warning("Will this type have any purpose?")

public struct JWSAlgorithm: RawRepresentable, Hashable, ExpressibleByStringLiteral  {
    
    public var rawValue: String
    
    public init(rawValue: String) {
        
        self.rawValue = rawValue
    }
    
    public init(stringLiteral value: String) {
        
        self.init(rawValue: value)
    }
}

extension JWSAlgorithm {
    
    public static let HS256: JWSAlgorithm = "HS256"
    public static let RS256: JWSAlgorithm = "RS256"
}
