//
//  AnyNetworkClient.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 11.08.18.
//  Copyright © 2018 Milen Halachev. All rights reserved.
//

import Foundation

///A default, closure based implementation of NetworkClient
public struct AnyNetworkClient: NetworkClient {
    
    public let handler: (_ request: URLRequest) async throws -> NetworkResponse
    
    public init(handler: @escaping (_ request: URLRequest) async throws -> NetworkResponse) {
        
        self.handler = handler
    }
    
    public init(other networkClient: NetworkClient) {
        
        self.init(handler: networkClient.perform)
    }
    
    public func perform(_ request: URLRequest) async throws -> NetworkResponse {
        
        try await handler(request)
    }
}

extension NetworkClient where Self == AnyNetworkClient {
    
    public static func any(handler: @escaping (_ request: URLRequest) async throws -> NetworkResponse) -> Self {
        
        .init(handler: handler)
    }
}
