//
//  SecKeyFactory+RSAPublicKey.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 22.08.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation
import Security

extension SecKeyFactory {
    
    /**
     Creates a SecKey instnace that represents a RSA public key of a given size.
     
     - parameter data: The key data.
     - parameter keySize: The key size in bits.
     - returns: An instance of SecKey or nil if the creation fails.
     */
    
    public static func makeRSAPublicKey(from data: Data, keySize: Int) throws -> SecKey {
        
        if #available(iOS 10.0, *), #available(macOS 10.12, *), #available(tvOS 10.0, *), #available(watchOS 3.0, *) {
            
            return try _makeRSAPublicKey_modern(from: data, keySize: keySize)
        }
        else {
            
            return try _makeRSAPublicKey_legacy(from: data)
        }
    }
    
    #if os(macOS)
    static func _makeRSAPublicKey_legacy(from data: Data) throws -> SecKey {
        
        //add the key to the keychain in order to retrieve a reference to it
        var result: CFArray?
        let status = SecItemImport(data as CFData, nil, nil, nil, .pemArmour, nil, nil, &result)
        
        guard status == errSecSuccess else {
            
            throw OSStatusGetError(status)
        }
        
        
        guard let resultRef = (result as [CFTypeRef]?)?.first else {
            
            throw MHIdentityKitError.publicKeyCreationFailed(reason: MHIdentityKitError.Reason.unknown)
        }
        
        guard CFGetTypeID(resultRef) == SecKeyGetTypeID() else {
            
            throw MHIdentityKitError.publicKeyCreationFailed(reason: MHIdentityKitError.Reason.typeMismatch(expected: "\(SecKeyGetTypeID())", actual: "\(CFGetTypeID(resultRef))"))
        }
        
        let key = resultRef as! SecKey
        return key
    }
    #else
    static func _makeRSAPublicKey_legacy(from data: Data) throws -> SecKey {
        
        //Safe force unwrap - https://www.objc.io/blog/2018/02/13/string-to-data-and-back/
        let tag = NSUUID().uuidString.data(using: .utf8)!
        
        let attributes = [
            
            kSecClass: kSecClassKey,
            kSecValueData: data,
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecAttrApplicationTag: tag,
            kSecReturnRef: true
            
            ] as CFDictionary
        
        var result: CFTypeRef?
        let status = SecItemAdd(attributes, &result)
        
        guard status == errSecSuccess else {
            
            throw OSStatusGetError(status)
        }
        
        guard let resultRef = result else {
            
            throw MHIdentityKitError.publicKeyCreationFailed(reason: MHIdentityKitError.Reason.unknown)
        }
        
        guard CFGetTypeID(resultRef) == SecKeyGetTypeID() else {
            
            throw MHIdentityKitError.publicKeyCreationFailed(reason: MHIdentityKitError.Reason.typeMismatch(expected: "\(SecKeyGetTypeID())", actual: "\(CFGetTypeID(resultRef))"))
        }
        
        let key = resultRef as! SecKey
        
        //delete the key from the keychain - we don't need to persist it
        _ = SecItemDelete(attributes)
        
        return key
    }
    #endif
    
    @available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *)
    static func _makeRSAPublicKey_modern(from data: Data, keySize: Int) throws -> SecKey {
        
        let attributes = [kSecAttrKeyType: kSecAttrKeyTypeRSA, kSecAttrKeyClass: kSecAttrKeyClassPublic, kSecAttrKeySizeInBits: keySize] as CFDictionary
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(data as CFData, attributes, &error) else {
            
            throw error?.takeRetainedValue() ?? MHIdentityKitError.publicKeyCreationFailed(reason: MHIdentityKitError.Reason.unknown)
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
    
    public init(RSAPublicKey data: Data, keySize: Int) throws {
        
        self = try Self.makeRSAPublicKey(from: data, keySize: keySize)
    }
}
