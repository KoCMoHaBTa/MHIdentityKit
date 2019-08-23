//
//  SecKeyVerifySignatureVerifier.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 21.08.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation

@available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *)
public struct SecKeyVerifySignatureVerifier: SignatureVerifier {
    
    ///The public key used for signing.
    public var key: SecKey
    
    ///The algorithm that was used to create the signature. Use one of the signing algorithms listed in SecKeyAlgorithm. You can use the SecKeyIsAlgorithmSupported(_:_:_:) function to test that the key is suitable for the algorithm.
    public var algorithm: SecKeyAlgorithm
    
    public init(key: SecKey, algorithm: SecKeyAlgorithm) {
        
        self.key = key
        self.algorithm = algorithm
    }
    
    public func verify(input: Data, withSignature signature: Data) throws {
        
        var error: Unmanaged<CFError>?
        guard SecKeyVerifySignature(self.key, self.algorithm, input as CFData, signature as CFData, &error) else {
            
            throw error?.takeRetainedValue() as Error? ?? MHIdentityKitError.signatureVerificationFailed(reason: MHIdentityKitError.Reason.unknown)
        }
    }
}
