//
//  ErrorResponse.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 4/12/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

public struct ErrorResponse: LocalizedError, Codable {
    
    public enum Code: String, Codable {
        
        //https://tools.ietf.org/html/rfc6749#section-5.2
        case invalidRequest = "invalid_request"
        case invalidClient = "invalid_client"
        case invalidGrant = "invalid_grant"
        case unauthorizedClient = "unauthorized_client"
        case unsupportedGrantType = "unsupported_grant_type"
        case invalidScope = "invalid_scope"
        
        //https://tools.ietf.org/html/rfc6749#section-4.1.2.1
        case accessDenied = "access_denied"
        case unsupportedResponseType = "unsupported_response_type"
        case serverError = "server_error"
        case temporarilyUnavailable = "temporarily_unavailable"
    }
    
    public var code: Code
    public var description: String?
    public var uri: String?
    
    public init(code: Code, description: String? = nil, uri: String? = nil) {
        
        self.code = code
        self.description = description
        self.uri = uri
    }
    
    public init?(parameters: [String: Any]) {
        
        guard let data = try? JSONSerialization.data(withJSONObject: parameters, options: []), let object = try? JSONDecoder().decode(ErrorResponse.self, from: data) else {
            
            return nil
        }
        
        self = object
    }
    
    //MARK: - Codable
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.code = try container.decode(Code.self, forKey: .code)
        self.description = try? container.decode(String.self, forKey: .description)
        self.uri = try? container.decode(String.self, forKey: .uri)
    }
    
    enum CodingKeys: String, CodingKey {
        
        case code = "error"
        case description = "error_description"
        case uri = "error_uri"
    }
    
    //MARK: - LocalizedError
    
    public var errorDescription: String? {
        
        return self.code.rawValue
    }
    
    public var failureReason: String? {
        
        return self.description
    }
}
