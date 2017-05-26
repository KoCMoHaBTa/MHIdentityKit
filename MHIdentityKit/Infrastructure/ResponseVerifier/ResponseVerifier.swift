//
//  ResponseVerifier.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 4/12/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///A type that verifies a network data, response and error
public protocol ResponseVerifier {
    
    /**
     Verifies provided data, response and error, returned from a HTTP request.
     
     - parameter data: The data to verify.
     - parameter response: The response to verify.
     - parameter error: The error to verify.
     - throws: An error if the verification fails.
     - returns: This method returns without throwing any error if the verification was sucessfull.
     */
    func verify(data: Data?, response: URLResponse?, error: Error?) throws
}





