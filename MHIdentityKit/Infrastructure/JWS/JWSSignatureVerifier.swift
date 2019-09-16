//
//  JWSSignatureVerifier.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 27.08.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation

///A type that verifies a JWS token
public protocol JWSSignatureVerifier {
    
    func verify(token: JWT) throws
}
