//
//  ErrorResponse.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 4/12/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

public struct ErrorResponse: LocalizedError {
    
    public enum Code: String {
        
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
        
        guard
        let codeRawValue = parameters["error"] as? String,
        let code = Code(rawValue: codeRawValue)
        else {
            
            return nil
        }
        
        self.code = code
        self.description = parameters["error_description"] as? String
        self.uri = parameters["error_uri"] as? String
    }
    
    public var errorDescription: String? {
        
        return self.code.rawValue
    }
    
    public var failureReason: String? {
        
        return self.description
    }
}
