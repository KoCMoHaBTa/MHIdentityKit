//
//  Scope.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/25/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

//https://tools.ietf.org/html/rfc6749#section-3.3
public struct Scope  {

    var value: String
    
    public var components: [String] {
        
        return self.value.components(separatedBy: " ")
    }
    
    public init(value: String) {
        
        self.value = value
    }
    
    public init(components: [String]) {
        
        self.init(value: components.joined(separator: " "))
    }
}

//MARK: - RawRepresentable
extension Scope: RawRepresentable {
    
    public var rawValue: String {
        
        get { return self.value }
        set { self.value = newValue }
    }
    
    public init?(rawValue: String) {
        
        self.init(value: rawValue)
    }
}

//MARK: - ExpressibleByStringLiteral
extension Scope: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        
        self.init(value: value)
    }
    
    public init(unicodeScalarLiteral value: String) {
        
        self.init(value: value)
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        
        self.init(value: value)
    }
}

//MARK: - ExpressibleByArrayLiteral
extension Scope: ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: String...) {
        
        self.init(components: elements)
    }
}

//MARK: - CustomStringConvertible
extension Scope: CustomStringConvertible {
    
    public var description: String {
        
        return self.value
    }
}
