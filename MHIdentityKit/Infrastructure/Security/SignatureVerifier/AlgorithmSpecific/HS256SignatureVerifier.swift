//
//  HS256SignatureVerifier.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 21.08.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation
import Security
import CommonCrypto

public struct HS256SignatureVerifier: SignatureVerifier {
    
    public var secret: String
    
    public init(secret: String) {
        
        self.secret = secret
    }
    
    public func verify(input: Data, withSignature signature: Data) throws {
        
        try CCHmacSignatureVerifier(algorithm: CCHmacAlgorithm(kCCHmacAlgSHA256), secret: self.secret).verify(input: input, withSignature: signature)
    }
}
