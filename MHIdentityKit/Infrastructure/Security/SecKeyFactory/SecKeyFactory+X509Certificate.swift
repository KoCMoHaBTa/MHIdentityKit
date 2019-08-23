//
//  SecKeyFactory+X509Certificate.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 22.08.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation

extension SecKeyFactory {
    
    /**
     - parameter data: A DER (Distinguished Encoding Rules) representation of an X.509 certificate.
     */
    public static func makeRSAPublicKey(fromX509Certificate data: Data) throws -> SecKey {
        
        if #available(iOS 12.0, *), #available(macOS 10.14, *), #available(tvOS 12.0, *), #available(watchOS 5.0, *) {
            
            return try _makeRSAPublicKey_modern(fromX509Certificate: data)
        }
        else {
            
            return try _makeRSAPublicKey_legacy(fromX509Certificate: data)
        }
    }
    
    static func _makeRSAPublicKey_legacy(fromX509Certificate data: Data) throws -> SecKey {
        
        guard let certificate = SecCertificateCreateWithData(nil, data as CFData) else {
            
            throw MHIdentityKitError.publicKeyCreationFailed(reason: MHIdentityKitError.Reason.invalidCertificate)
        }
        
        var trust: SecTrust?
        let status = SecTrustCreateWithCertificates(certificate, SecPolicyCreateBasicX509(), &trust)

        guard status == errSecSuccess else {
            
            throw OSStatusGetError(status)
        }
        
        guard let trustRef = trust else {
            
            throw MHIdentityKitError.publicKeyCreationFailed(reason: MHIdentityKitError.Reason.invalidCertificate)
        }
        
        guard let key = SecTrustCopyPublicKey(trustRef) else {
            
            throw MHIdentityKitError.publicKeyCreationFailed(reason: MHIdentityKitError.Reason.invalidCertificate)
        }
        
        return key
    }
    
    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
    static func _makeRSAPublicKey_modern(fromX509Certificate data: Data) throws -> SecKey {
        
        guard let certificate = SecCertificateCreateWithData(nil, data as CFData) else {
            
            throw MHIdentityKitError.publicKeyCreationFailed(reason: MHIdentityKitError.Reason.invalidCertificate)
        }
        
        guard let key = SecCertificateCopyKey(certificate) else {
            
            throw MHIdentityKitError.publicKeyCreationFailed(reason: MHIdentityKitError.Reason.invalidCertificate)
        }
        
        return key
    }
}

extension SecKeyFactory where Self == SecKey {
    
    /**
     Creates a SecKey instnace that represents a RSA public key of a given size.
     
     - parameter data: The key data.
     - parameter keySize: The key size in bits.
     - returns: An instance of SecKey or nil if the creation fails.
     */
    
    public init(X509Certificate data: Data) throws {
        
        self = try Self.makeRSAPublicKey(fromX509Certificate: data)
    }
}
