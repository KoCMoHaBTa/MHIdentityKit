//
//  AnyNetworkResponseValidator.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 4.08.18.
//  Copyright © 2018 Milen Halachev. All rights reserved.
//

import Foundation

///A default, closures based, implementation of NetworkResponseValidator
public struct AnyNetworkResponseValidator: NetworkResponseValidator {
    
    public let handler: (NetworkResponse) -> Bool
    
    public init(handler: @escaping (NetworkResponse) -> Bool) {
        
        self.handler = handler
    }
    
    public init(other validator: NetworkResponseValidator) {
        
        self.handler = validator.validate(_:)
    }
    
    public func validate(_ response: NetworkResponse) -> Bool {
        
        return self.handler(response)
    }
}

extension NetworkResponseValidator where Self == AnyNetworkResponseValidator {
    
    public static func any(handler: @escaping (NetworkResponse) -> Bool) -> Self {
        
        .init(handler: handler)
    }
}
