//
//  SecKeyFactoryError.swift
//  SecKeyFactoryError
//
//  Created by Milen Halachev on 6.08.21.
//  Copyright © 2021 Milen Halachev. All rights reserved.
//

import Foundation

public enum SecKeyFactoryError: Swift.Error {
    
    ///Indicates the operation was successful, but did not return a result.
    case misingResult
    
    ///Indicates that the operation was successful, but the result type did not match the expected one.
    case typeMismatch(expected: String, actual: String)
    
    ///Indicates that public key creation failed without known reason.
    case unableToCreatePublicKey
    
    ///Indicates that the certificate import has failed.
    case unableToImportCertificate

    ///Indicates that the operation was unable to retrieve the public key from the provided certificate
    case unableToRetrievePublicKeyFromCertificate
}

extension SecKeyFactory {
    
    typealias Error = SecKeyFactoryError
}
