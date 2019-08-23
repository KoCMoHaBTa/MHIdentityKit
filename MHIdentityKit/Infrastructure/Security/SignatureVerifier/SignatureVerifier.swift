//
//  SignatureVerifier.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 21.08.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation

///A type that verifiers a digital signature
public protocol SignatureVerifier {
    
    ///Verifiers a digital signature. If verification is successful, the function completes without any errors, otherwise throws an exception.
    func verify(input: Data, withSignature signature: Data) throws
}

/*
 
 https://tools.ietf.org/html/draft-ietf-jose-json-web-algorithms-40#section-3.1
 
| HS256        | HMAC using SHA-256                | Required       |   Implemented
| HS384        | HMAC using SHA-384                | Optional       |
| HS512        | HMAC using SHA-512                | Optional       |
| RS256        | RSASSA-PKCS-v1_5 using SHA-256    | Recommended    |   Implemented
| RS384        | RSASSA-PKCS-v1_5 using SHA-384    | Optional       |
| RS512        | RSASSA-PKCS-v1_5 using SHA-512    | Optional       |
| ES256        | ECDSA using P-256 and SHA-256     | Recommended+   |   Implemented
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


