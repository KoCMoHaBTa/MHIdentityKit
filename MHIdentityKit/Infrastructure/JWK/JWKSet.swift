//
//  JWKSet.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 2.04.21.
//  Copyright © 2021 Milen Halachev. All rights reserved.
//

import Foundation

/// https://tools.ietf.org/html/draft-ietf-jose-json-web-key-41#section-5
public class JWKSet {
    
    public let url: URL
    public let networkClient: NetworkClient
    public private(set) var keys: [JWK] = []
    
    public init(url: URL, networkClient: NetworkClient = .default) {
        
        self.url = url
        self.networkClient = networkClient
    }
    
    public func update() async throws {
        
        let request = URLRequest(url: url)
        let response = try await networkClient.perform(request)
        let data = response.data
        
        guard
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
        let keys = json["keys"] as? [[String: Any]]
        else {
            
            throw Error.unableToParseJWKSet
        }
        
        try self.keys = keys.map { try .init(parameters: $0) }
    }
    
    public func findKey(withID kid: String) async -> JWK? {
    
        if let key = keys.first(where: { $0.kid == kid }) {
            
            return key
        }
        
        try? await update()
        
        return keys.first(where: { $0.kid == kid })
    }
}

extension JWKSet {
    
    public enum Error: Swift.Error {
        
        case unableToParseJWKSet
    }
}
