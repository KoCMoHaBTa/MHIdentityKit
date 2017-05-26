//
//  Collection+ResponseVerifier.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/26/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///ResponseVerifier composition
extension Collection where Iterator.Element == ResponseVerifier {
    
    /**
     Performs veifircation of provided parameters with each verifier in the receiver collection
     
     - parameter data: The data to verify.
     - parameter response: The response to verify.
     - parameter error: The error to verify.
     - throws: An error of the first verification that fails.
     - returns: This method returns without throwing any error if the verification of all elements in the receiver was sucessfull.
     */
    func verify(data: Data?, response: URLResponse?, error: Error?) throws {
        
        try self.forEach { (verifier) in
            
            try verifier.verify(data: data, response: response, error: error)
        }
    }
}
