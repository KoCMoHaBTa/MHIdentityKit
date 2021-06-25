//
//  Scope.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/25/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

//https://tools.ietf.org/html/rfc6749#section-3.3
public struct Scope: RawRepresentable, ExpressibleByStringLiteral, ExpressibleByArrayLiteral, CustomStringConvertible, Equatable, Codable  {

    public var rawValue: String
    
    public var components: [String] {
        
        rawValue.components(separatedBy: " ")
    }
    
    public init(rawValue: String) {
        
        self.rawValue = rawValue
    }
    
    public init(components: [String]) {
        
        self.init(rawValue: components.joined(separator: " "))
    }
    
    public init(stringLiteral value: String) {
        
        self.init(rawValue: value)
    }
    
    public init(arrayLiteral elements: String...) {
        
        self.init(components: elements)
    }
    
    public var description: String { rawValue }
}
