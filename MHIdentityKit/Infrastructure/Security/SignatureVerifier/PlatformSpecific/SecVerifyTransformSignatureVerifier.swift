//
//  SecVerifyTransformSignatureVerifier.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 21.08.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation
import Security

///A signature verifier that uses SecVerifyTransform
public struct SecVerifyTransformSignatureVerifier: SignatureVerifier {
    
    ///The public key used for signing.
    public var key: SecKey
    
    /**
     The transform attributes used by [SecTransformSetAttribute](https://developer.apple.com/documentation/security/1393861-sectransformsetattribute?language=objc).
     
     For a list of valid keys and possible values, see [Transform Attributes](https://developer.apple.com/documentation/security/security_transforms/transform_attributes?language=objc)
     */
    
    public var attributes: [CFString: CFTypeRef] = [:]
    
    /**
     Creates an instance of the receiver with a key and attributes, used to build the security transform.
     
     - parameter key: The public key used for signing.
     - parameter attributes: The transform attributes used by [SecTransformSetAttribute](https://developer.apple.com/documentation/security/1393861-sectransformsetattribute?language=objc). For a list of valid keys and possible values, see [Transform Attributes](https://developer.apple.com/documentation/security/security_transforms/transform_attributes?language=objc)
     */
    
    public init(key: SecKey, attributes: [CFString: CFTypeRef]) {
        
        self.key = key
        self.attributes = attributes
    }
    
    /**
     Creates an instance of the receiver with a key, digest type and lenght.
     
     - parameter key: The public key used for signing.
     - parameter digestType: Use one of the values listed in [Digest Types](https://developer.apple.com/documentation/security/security_transforms/transform_attributes?language=objc#2872573).
     - parameter digestLength: The value is a `CFNumber` that contains the digest length.
     */
    
    public init(key: SecKey, digestType: CFString, digestLength: Int) {
        
        self.init(key: key, attributes: [kSecDigestTypeAttribute: digestType, kSecDigestLengthAttribute: digestLength as CFNumber])
    }
    
    public func verify(input: Data, withSignature signature: Data) throws {
        
        guard let transform = SecVerifyTransformCreate(self.key, signature as CFData, nil) else {
            
            throw MHIdentityKitError.signatureVerificationFailed(reason: MHIdentityKitError.Reason.unableToCreateSecurityTransform)
        }
        
        var error: Unmanaged<CFError>?
        guard attributes.reduce(true, { (result, pair) -> Bool in
            
            return result && SecTransformSetAttribute(transform, pair.key, pair.value, &error)
        })
        else {
            
            throw error?.takeRetainedValue() as Error? ?? MHIdentityKitError.signatureVerificationFailed(reason: MHIdentityKitError.Reason.unableToSetSecurityTransformAttributes)
        }
        
        guard SecTransformSetAttribute(transform, kSecTransformInputAttributeName, input as CFData, &error) else {

            throw error?.takeRetainedValue() as Error? ?? MHIdentityKitError.signatureVerificationFailed(reason: MHIdentityKitError.Reason.unableToSetSecurityTransformAttributes)
        }
        
        guard let result = SecTransformExecute(transform, &error) as? Bool, result == true else {
            
            throw error?.takeRetainedValue() as Error? ?? MHIdentityKitError.signatureVerificationFailed(reason: MHIdentityKitError.Reason.unableToExecuteSecurityTransform)
        }
    }
}
