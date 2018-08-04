//
//  AnyUserAgent.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 4.08.18.
//  Copyright © 2018 Milen Halachev. All rights reserved.
//

import Foundation

///A default, closures based, implementation of UserAgent
public struct AnyUserAgent: UserAgent {
    
    public let handler: (_ request: URLRequest, _ redirectURI: URL?, _ redirectionHandler: @escaping (URLRequest) throws -> Bool) -> Void
    
    public init(handler: @escaping (_ request: URLRequest, _ redirectURI: URL?, _ redirectionHandler: @escaping (URLRequest) throws -> Bool) -> Void) {
        
        self.handler = handler
    }
    
    public init(other userAgent: UserAgent) {
        
        self.handler = userAgent.perform(_:redirectURI:redirectionHandler:)
    }
    
    public func perform(_ request: URLRequest, redirectURI: URL?, redirectionHandler: @escaping (URLRequest) throws -> Bool) {
    
        self.handler(request, redirectURI, redirectionHandler)
    }
}
