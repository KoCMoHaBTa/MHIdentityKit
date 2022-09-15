//
//  AnyRequestAuthorizer.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 11.08.18.
//  Copyright © 2018 Milen Halachev. All rights reserved.
//

import Foundation

///A default, closure based implementation of RequestAuthorizer
public struct AnyRequestAuthorizer: RequestAuthorizer {
    
    public let handler: (_ request: URLRequest, _ handler: @escaping (URLRequest, Error?) -> Void) -> Void
    
    public init(handler: @escaping (_ request: URLRequest, _ handler: @escaping (URLRequest, Error?) -> Void) -> Void) {
        
        self.handler = handler
    }
    
    public init(other requestAuthorizer: RequestAuthorizer) {
        
        self.handler = requestAuthorizer.authorize(request:handler:)
    }
    
    public func authorize(request: URLRequest, handler: @escaping (URLRequest, Error?) -> Void) {
        
        self.handler(request, handler)
    }
    
    @available(iOS 13, tvOS 13.0.0, macOS 10.15, *)
    public func authorize(request: URLRequest) async throws -> URLRequest {
        
        return request
    }
}
