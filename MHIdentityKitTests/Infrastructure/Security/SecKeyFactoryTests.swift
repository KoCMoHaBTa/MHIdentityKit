//
//  SecKeyFactoryTests.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 22.08.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import MHIdentityKit

class SecKeyFactoryTests: XCTestCase {
    
    @available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *)
    func testModernPKCS1RSAPublicKey() {
        
        XCTAssertNoThrow(try SecKey._makeRSAPublicKey_modern(from: Data(base64Encoded: MockRSA().publicKeyPKCS1)!, keySize: 2048))
        XCTAssertThrowsError(try SecKey._makeRSAPublicKey_modern(from: Data(base64Encoded: MockRSA().publicKeyPKCS1)!.dropLast(1), keySize: 2048))
    }
    
    func testLegacyPKCS1RSAPublicKey() {
        
        XCTAssertNoThrow(try SecKey._makeRSAPublicKey_legacy(from: Data(base64Encoded: MockRSA().publicKeyPKCS1)!))
        XCTAssertThrowsError(try SecKey._makeRSAPublicKey_legacy(from: Data(base64Encoded: MockRSA().publicKeyPKCS1)!.dropLast(1)))
    }
    
    @available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *)
    func testModernPKCS8RSAPublicKey() {
        
        XCTAssertNoThrow(try SecKey._makeRSAPublicKey_modern(from: Data(base64Encoded: MockRSA().publicKeyPKCS8)!, keySize: 2048))
        XCTAssertThrowsError(try SecKey._makeRSAPublicKey_modern(from: Data(base64Encoded: MockRSA().publicKeyPKCS8)!.dropLast(1), keySize: 2048))
    }
    
    func testLegacyPKCS8RSAPublicKey() {
        
        XCTAssertNoThrow(try SecKey._makeRSAPublicKey_legacy(from: Data(base64Encoded: MockRSA().publicKeyPKCS8)!))
        XCTAssertThrowsError(try SecKey._makeRSAPublicKey_legacy(from: Data(base64Encoded: MockRSA().publicKeyPKCS8)!.dropLast(1)))
    }
    
    func testPKCS1RSAPublicKey() {
        
        XCTAssertNoThrow(try SecKey.makeRSAPublicKey(from: Data(base64Encoded: MockRSA().publicKeyPKCS1)!, keySize: 2048))
        XCTAssertThrowsError(try SecKey.makeRSAPublicKey(from: Data(base64Encoded: MockRSA().publicKeyPKCS1)!.dropLast(1), keySize: 2048))
        XCTAssertNoThrow(try SecKey(RSAPublicKey: Data(base64Encoded: MockRSA().publicKeyPKCS1)!, keySize: 2048))
        XCTAssertThrowsError(try SecKey(RSAPublicKey: Data(base64Encoded: MockRSA().publicKeyPKCS1)!.dropLast(1), keySize: 2048))
    }
    
    func testPKCS8RSAPublicKey() {
     
        XCTAssertNoThrow(try SecKey.makeRSAPublicKey(from: Data(base64Encoded: MockRSA().publicKeyPKCS8)!, keySize: 2048))
        XCTAssertThrowsError(try SecKey.makeRSAPublicKey(from: Data(base64Encoded: MockRSA().publicKeyPKCS8)!.dropLast(1), keySize: 2048))
        XCTAssertNoThrow(try SecKey(RSAPublicKey: Data(base64Encoded: MockRSA().publicKeyPKCS8)!, keySize: 2048))
        XCTAssertThrowsError(try SecKey(RSAPublicKey: Data(base64Encoded: MockRSA().publicKeyPKCS8)!.dropLast(1), keySize: 2048))
    }
    
    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
    func testModernX509CertificateRSAPublicKey() {
     
        XCTAssertNoThrow(try SecKey._makeRSAPublicKey_modern(fromX509Certificate: Data(base64Encoded: MockX509().certificate)!))
        XCTAssertThrowsError(try SecKey._makeRSAPublicKey_modern(fromX509Certificate: Data(base64Encoded: MockX509().certificate)!.dropLast(1)))
    }
    
    func testLegacyX509CertificateRSAPublicKey() {
        
        XCTAssertNoThrow(try SecKey._makeRSAPublicKey_legacy(fromX509Certificate: Data(base64Encoded: MockX509().certificate)!))
        XCTAssertThrowsError(try SecKey._makeRSAPublicKey_legacy(fromX509Certificate: Data(base64Encoded: MockX509().certificate)!.dropLast(1)))
    }
    
    func testX509CertificateRSAPublicKey() {
        
        XCTAssertNoThrow(try SecKey.makeRSAPublicKey(fromX509Certificate: Data(base64Encoded: MockX509().certificate)!))
        XCTAssertThrowsError(try SecKey.makeRSAPublicKey(fromX509Certificate: Data(base64Encoded: MockX509().certificate)!.dropLast(1)))
        XCTAssertNoThrow(try SecKey(X509Certificate: Data(base64Encoded: MockX509().certificate)!))
        XCTAssertThrowsError(try SecKey(X509Certificate: Data(base64Encoded: MockX509().certificate)!.dropLast(1)))
    }
}
