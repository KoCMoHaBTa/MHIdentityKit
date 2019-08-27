//
//  SignatureVerifierTests.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 22.08.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import MHIdentityKit

class SignatureVerifierTests: XCTestCase {
 
    func testRS256SignatureVerifier() {
     
        XCTAssertNoThrow(try {
            
            let mock = MockRS256()
            let verifier = try RS256SignatureVerifier(X509CertificateData: Data(base64Encoded: mock.certificate)!)
            let input = mock.input
            let signature = mock.signature
            try verifier.verify(input: input, withSignature: signature)
        }())
    }
    
    func testHS256SignatureVerifier() {
        
        XCTAssertNoThrow(try {
            
            let mock = MockHS256()
            let verifier = try HS256SignatureVerifier(secret: mock.secret)
            let input = mock.input
            let signature = mock.signature
            try verifier.verify(input: input, withSignature: signature)
        }())
    }
    
    func testES256SignatureVerifier() {
        
        XCTFail()
    }
}
