//
//  ErrorResponse.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 4/12/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

//https://tools.ietf.org/html/rfc6749#section-5.2
public struct ErrorResponse: Error {
    
    public enum Code: String {
        
        case invalidRequest = "invalid_request"
        case invalidClient = "invalid_client"
        case invalidGrant = "invalid_grant"
        case unauthorizedClient = "unauthorized_client"
        case unsupportedGrantType = "unsupported_grant_type"
        case invalidScope = "invalid_scope"
    }
    
    public var code: Code
    public var description: String?
    public var uri: String?
    
    public init(code: Code, description: String? = nil, uri: String? = nil) {
        
        self.code = code
        self.description = description
        self.uri = uri
    }
    
    public init?(json: [String: Any]) {
        
        guard
        let codeRawValue = json["error"] as? String,
        let code = Code(rawValue: codeRawValue)
        else {
            
            return nil
        }
        
        self.code = code
        self.description = json["error_description"] as? String
        self.uri = json["error_uri"] as? String
    }
}
