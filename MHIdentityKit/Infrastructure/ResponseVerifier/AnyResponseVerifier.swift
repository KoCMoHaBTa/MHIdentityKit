//
//  AnyResponseVerifier.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/26/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///A closure based ResponseVerifier
public struct AnyResponseVerifier: ResponseVerifier {
    
    public let handler: (Data?, URLResponse?, Error?) throws -> Void
    
    public init(handler: @escaping (Data?, URLResponse?, Error?) throws -> Void) {
        
        self.handler = handler
    }
    
    public init(verifier: ResponseVerifier) {
        
        self.handler = verifier.verify
    }
    
    public init(verifier: [ResponseVerifier]) {
        
        self.handler = verifier.verify
    }
    
    public func verify(data: Data?, response: URLResponse?, error: Error?) throws {
        
        try self.handler(data, response, error)
    }
}

