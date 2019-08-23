//
//  RS256SignatureVerifier.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 21.08.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation

public struct RS256SignatureVerifier: SignatureVerifier {
    
    ///The public key used for signing.
    public var key: SecKey
    
    ///Creates an instance of the receiver with a public key.
    public init(key: SecKey) {
        
        self.key = key
    }
    
    ///Creates an instance of the receiver with a public key data and size.
    public init(keyData: Data, keySize: Int) throws {
        
        self.key = try SecKey(RSAPublicKey: keyData, keySize: keySize)
    }
    
    ///Creates an instance of the receiver with a X509 certificate data.
    public init(X509CertificateData: Data) throws {
        
        self.key = try SecKey(X509Certificate: X509CertificateData)
    }
    
    public func verify(input: Data, withSignature signature: Data) throws {
        
        let verifier: SignatureVerifier
        
        if #available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *) {
            
            verifier = SecKeyVerifySignatureVerifier(key: self.key, algorithm: .rsaSignatureMessagePKCS1v15SHA256)
        }
        else {
            
            #if os(macOS)
            verifier = SecVerifyTransformSignatureVerifier(key: self.key, digestType: kSecDigestSHA2, digestLength: 256)
            #else
            verifier = SecKeyRawVerifySignatureVerifier(key: self.key, algorithm: .sha256)
            #endif
        }
        
        try verifier.verify(input: input, withSignature: signature)
    }
}
