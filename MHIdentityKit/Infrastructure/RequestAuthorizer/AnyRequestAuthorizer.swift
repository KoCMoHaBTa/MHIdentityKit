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
    
    public let handler: (_ request: URLRequest) async throws -> URLRequest
    
    public init(handler: @escaping (_ request: URLRequest) async throws -> URLRequest) {
        
        self.handler = handler
    }
    
    public init(other requestAuthorizer: RequestAuthorizer) {
        
        self.init(handler: requestAuthorizer.authorize(request:))
    }
    
    public func authorize(request: URLRequest) async throws -> URLRequest {
        
        try await handler(request)
    }
}

extension RequestAuthorizer where Self == AnyRequestAuthorizer {
    
    public static func any(handler: @escaping (_ request: URLRequest) async throws -> URLRequest) -> Self {
        
        .init(handler: handler)
    }
}
