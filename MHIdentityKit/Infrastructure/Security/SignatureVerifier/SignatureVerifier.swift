//
//  SignatureVerifier.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 21.08.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation

///A type that verifiers a digital signature
public protocol SignatureVerifier {
    
    ///Verifiers a digital signature. If verification is successful, the function completes without any errors, otherwise throws an exception.
    func verify(input: Data, withSignature signature: Data) throws
}

