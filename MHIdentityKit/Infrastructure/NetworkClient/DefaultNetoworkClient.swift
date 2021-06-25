//
//  DefaultNetoworkClient.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/26/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///A default implementation of a NetworkClient, used internally
public class DefaultNetoworkClient: NetworkClient {
    
    private let session = URLSession(configuration: .ephemeral)
    
    public func perform(_ request: URLRequest) async throws -> NetworkResponse {
        
        if #available(iOS 15.0, *) {
            let (data, response) = try await session.data(for: request, delegate: nil)
            return .init(data: data, response: response)
        }
        else {
        
            fatalError("Xcode 13 Beta 1 requires iOS 15 for all async/await APIs ")
        }
    }
    
    deinit {
        
        self.session.invalidateAndCancel()
    }
}

extension DefaultNetoworkClient {
    
    ///A shared singleton instance of the receiver
    public static let shared: DefaultNetoworkClient = .init()
}

extension NetworkClient where Self == DefaultNetoworkClient {

    ///The shared instance of the default network client
    public static var `default`: Self { .shared }
}
