//
//  NetworkResponseValidator.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 7/10/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///A type that validates network response
public protocol NetworkResponseValidator {
    
    ///Validates a network response and returns true if valid and false if invalid
    func validate(_ response: NetworkResponse) -> Bool
}

///A default, closures based, implementation of NetworkResponseValidator
public struct AnyNetworkResponseValidator: NetworkResponseValidator {
    
    public let handler: (NetworkResponse) -> Bool
    
    public func validate(_ response: NetworkResponse) -> Bool {
        
        return self.handler(response)
    }
}
