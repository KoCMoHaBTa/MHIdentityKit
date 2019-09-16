//
//  JWSSignatureVerifierProvider.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 27.08.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation

///A type that provides a JWSSignatureVerifier based on JWT input
public struct JWSSignatureVerifierProvider {
    
    public var handler: (JWT) -> JWSSignatureVerifier?
    
    public init(handler: @escaping (JWT) -> JWSSignatureVerifier?) {
        
        self.handler = handler
    }
    
    public func provideSignatureVerifier(for token: JWT) -> JWSSignatureVerifier? {
        
        return self.handler(token)
    }
}
