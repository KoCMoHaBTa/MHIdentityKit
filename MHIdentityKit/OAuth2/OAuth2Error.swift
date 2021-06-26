//
//  OAuth2Error.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 4/12/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///An OAuth2 Error, returned from the server
public struct OAuth2Error: LocalizedError {
    
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
        
        //https://openid.net/specs/openid-connect-core-1_0.html#AuthError
        case interactionRequired = "interaction_required"
        case loginRequired = "login_required"
        case accountSelectionRequired = "account_selection_required"
        case consentRequired = "consent_required"
        case invalidRequestUri = "invalid_request_uri"
        case invalidRequestObject = "invalid_request_object"
        case requestNotSupported = "request_not_supported"
        case requestUriNotSupported = "request_uri_not_supported"
        case registrationNotSupported = "registration_not_supported"
    }
    
    public var code: Code
    public var description: String?
    public var uri: String?
    public var state: String?
    
    public init(code: Code, description: String? = nil, uri: String? = nil, state: String? = nil) {
        
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
        self.state = parameters["state"] as? String
    }
    
    //MARK: - LocalizedError
    public var errorDescription: String? { description ?? code.rawValue }
    public var failureReason: String? { code.rawValue }
}
