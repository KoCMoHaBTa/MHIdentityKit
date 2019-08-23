//
//  SecVerifyTransformSignatureVerifierTests.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 22.08.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import MHIdentityKit

class SecVerifyTransformSignatureVerifierTests: XCTestCase {
    
    func testRS256UsingPKCS1Key() {

        XCTAssertNoThrow(try {
            
            let mock = MockRSA()
            let key = try SecKey(RSAPublicKey: Data(base64Encoded: mock.publicKeyPKCS1)!, keySize: 2048)
            let verifier = SecVerifyTransformSignatureVerifier(key: key, digestType: kSecDigestSHA2, digestLength: 256)
            let input = mock.input
            let signature = mock.signature
            try verifier.verify(input: input, withSignature: signature)
        }())
    }

    func testRS256tUsingPKCS8Key() {

        XCTAssertNoThrow(try {
            
            let mock = MockRSA()
            let key = try SecKey(RSAPublicKey: Data(base64Encoded: MockRSA().publicKeyPKCS8)!, keySize: 2048)
            let verifier = SecVerifyTransformSignatureVerifier(key: key, digestType: kSecDigestSHA2, digestLength: 256)
            let input = mock.input
            let signature = mock.signature
            try verifier.verify(input: input, withSignature: signature)
        }())
    }

    func testRS256tUsingX509Certificate() {

        XCTAssertNoThrow(try {
            
            let mock = MockX509()
            let key = try SecKey(X509Certificate: Data(base64Encoded: mock.certificate)!)
            let verifier = SecVerifyTransformSignatureVerifier(key: key, digestType: kSecDigestSHA2, digestLength: 256)
            let input = mock.input
            let signature = mock.signature
            try verifier.verify(input: input, withSignature: signature)
        }())
    }
}


