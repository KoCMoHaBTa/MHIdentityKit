//
//  CCHmacSignatureVerifier.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 27.08.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation
import Security
import CommonCrypto

public struct CCHmacSignatureVerifier: SignatureVerifier {
    
    public var algorithm: CCHmacAlgorithm
    public var secret: String
    
    public init(algorithm: CCHmacAlgorithm, secret: String) {
        
        self.algorithm = algorithm
        self.secret = secret
    }
    
    public func verify(input: Data, withSignature signature: Data) throws {
        
        guard let keyNSData = self.secret.data(using: .utf8) as NSData? else {
            
            throw MHIdentityKitError.signatureVerificationFailed(reason: MHIdentityKitError.Reason.unknown)
        }
        
        let inputNSData = input as NSData
        
        let resultLen = Int(CC_SHA256_DIGEST_LENGTH)
        let result = UnsafeMutableRawPointer(UnsafeMutablePointer<UInt8>.allocate(capacity: resultLen))
        
        CCHmac(self.algorithm, keyNSData.bytes, keyNSData.length, inputNSData.bytes, inputNSData.length, result)
        
        guard Data(bytes: UnsafeRawPointer(result), count: resultLen) == signature else {
            
            throw MHIdentityKitError.signatureVerificationFailed(reason: MHIdentityKitError.Reason.unknown)
        }
    }
}
