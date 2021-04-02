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
    
    public init(url: URL, networkClient: NetworkClient = _defaultNetworkClient) {
        
        self.url = url
        self.networkClient = networkClient
        
        update()
    }
    
    public func update(_ completion: ((Swift.Error?) -> Void)? = nil) {
        
        let request = URLRequest(url: url)
        networkClient.perform(request) { (response) in
            
            if let error = response.error {
                
                completion?(error)
                return
            }
            
            do {
                
                guard
                let data = response.data,
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let keys = json["keys"] as? [[String: Any]]
                else {
                    
                    completion?(Error.unableToParseJWKSet)
                    return
                }
                
                try self.keys = keys.map { try .init(parameters: $0) }
            }
            catch {
                
                completion?(error)
            }
        }
    }
    
    public func findKey(withID kid: String) -> JWK? {
        
        keys.first(where: { $0.kid == kid })
    }
    
    public func findKey(withID kid: String, completion: @escaping (JWK?) -> Void) {
        
        if let key = findKey(withID: kid) {
            
            completion(key)
            return
        }
        
        update { [weak self] (_) in
            
            let key = self?.findKey(withID: kid)
            completion(key)
        }
    }
}

extension JWKSet {
    
    public enum Error: Swift.Error {
        
        case unableToParseJWKSet
    }
}
