//
//  SecKeyRawVerifySignatureVerifier.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 21.08.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation
import Security
import CommonCrypto

public struct SecKeyRawVerifySignatureVerifier: SignatureVerifier {
    
    ///The public key used for signing.
    public var key: SecKey
    
    public var algorithm: Algorithm
    
    public init(key: SecKey, algorithm: Algorithm) {
        
        self.key = key
        self.algorithm = algorithm
    }
    
    public func verify(input: Data, withSignature signature: Data) throws {
        
        let signature = signature as NSData
        
        let (signedData, signedDataLen) = self.algorithm.digestFunction(input)
        
        let sig = signature.bytes.assumingMemoryBound(to: UInt8.self)
        let sigLen = signature.length
        
        let status = SecKeyRawVerify(self.key, self.algorithm.padding, signedData, signedDataLen, sig, sigLen)
        guard status == errSecSuccess else {
            
            throw OSStatusGetError(status)
        }
    }
}

extension SecKeyRawVerifySignatureVerifier {
    
    public struct Algorithm {

        ///The types of padding to use when you create or verify a digital signature.
        public var padding: SecPadding

        ///provides the digest of the input data
        public var digestFunction: (Data) -> (digest: UnsafePointer<UInt8>, length: Int)
        
        public init(padding: SecPadding, digestFunction: @escaping (Data) -> (digest: UnsafePointer<UInt8>, length: Int)) {
            
            self.padding = padding
            self.digestFunction = digestFunction
        }
    }
}

extension SecKeyRawVerifySignatureVerifier.Algorithm {
    
    static let sha256: SecKeyRawVerifySignatureVerifier.Algorithm = .init(padding: .PKCS1SHA256) { (data) -> (digest: UnsafePointer<UInt8>, length: Int) in
        
        let data = data as NSData
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        let digest = UnsafeMutablePointer<UInt8>.allocate(capacity: digestLength)
        CC_SHA256(data.bytes, CC_LONG(data.length), digest)
        
        return (UnsafePointer(digest), digestLength)
    }
}
