//
//  MHIdentityKitError.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/22/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

public enum MHIdentityKitError: LocalizedError {
    
    case general(description: String, reason: String?)
    case authorizationFailed(reason: LocalizedError)
    case authenticationFailed(reason: LocalizedError)
    
    init(error: Error) {
        
        let error = error as NSError
        self = .general(description: error.localizedDescription, reason: error.localizedFailureReason)
    }
    
    private func expand() -> (errorDescription: String?, failureReason: String?, recoverySuggestion: String?) {
        
        switch self {
            
            case .general(let description, let reason):
                return (description, reason, nil)
            
            case .authorizationFailed(let reason):
                
                let description = NSLocalizedString("Unable to authorize the request", comment: "The error desciption when a request cannot be authorized")
                return (description, reason.failureReason, reason.recoverySuggestion)
            
            case .authenticationFailed(let reason):
                
                let description = NSLocalizedString("Unable to authenticate the client", comment: "The localized error desciption when client authentication fails")
                return (description, reason.failureReason, reason.recoverySuggestion)
            
        }
    }
    
    public var errorDescription: String? {
        
        return self.expand().errorDescription
    }
    
    public var failureReason: String? {
        
        return self.expand().failureReason
    }
    
    public var recoverySuggestion: String? {
     
        return self.expand().recoverySuggestion
    }
}

extension MHIdentityKitError {
    
    public enum Reason: LocalizedError {
        
        case general(message: String)
        case clientNotAuthenticated
        case tokenExpired
        case buildAuthenticationHeaderFailed
        case unknownURLResponse
        case unableToParseAccessToken
        case unableToParseData
        case unknownHTTPResponse(code: Int)
        case invalidRequestURL
        case invalidContentType
        case invalidRequestMethod
        
        private func expand() -> (failureReason: String?, recoverySuggestion: String?) {
            
            switch self {
                
                case .general(let message):
                    return (message, nil)
                
                case .clientNotAuthenticated:
                    
                    let reason = NSLocalizedString("The client is not authenticated", comment: "The error failure reason when a request cannot be authorized due to access token not existing")
                    let suggestion = NSLocalizedString("Try to authenticate the client", comment: "The error recovery suggestion when a request cannot be authorized")
                    
                    return (reason, suggestion)
                    
                case .tokenExpired:
                    
                    let reason = NSLocalizedString("The access token has expired", comment: "The error failure reason when a request cannot be authorized due to access token beign expired")
                    let suggestion = NSLocalizedString("Try to authenticate the client", comment: "The error recovery suggestion when a request cannot be authorized")
                    
                    return (reason, suggestion)
                
                case .buildAuthenticationHeaderFailed:
                
                    let reason = NSLocalizedString("Unable to build authentication header. Cannot create utf8 encoded data from the provided client and secret", comment: "The error failure reason when the authentication header could not be built from the provided clientID and secret.")
                    return (reason, nil)
                
                case .unknownURLResponse:
                
                    let reason = NSLocalizedString("Unknown url response", comment: "The localized error failure reason when the network response is unknown")
                    return (reason, nil)
                
                case .unableToParseAccessToken:
                    let reason = NSLocalizedString("Unable to parse access token data", comment: "The localized error description returned when the received access token response canot be read and/or parsed")
                    return (reason, nil)
                
                case .unableToParseData:
                    let reason = NSLocalizedString("Unable to parse data", comment: "The localized error description returned when the received data canot be read and/or parsed")
                    return (reason, nil)
                
                case .unknownHTTPResponse(let code):
                    let format = NSLocalizedString("Unknown HTTP response with code: %@", comment: "The localized error description returned when the response code is not sucess 2xx and no other has been handled")
                    let reason = String(format: format, code)
                    return (reason, nil)
                
                case .invalidRequestURL:
                    let reason = NSLocalizedString("The request has invalid URL", comment: "The localized error description returned when a URLRequest has invalid or nil URL")
                    return (reason, nil)
                
                case .invalidContentType:
                    let reason = NSLocalizedString("Invalid Content-Type.", comment: "The localized error description returned when a URLRequest has invalid or nil Content-Type header field")
                    return (reason, nil)
                
                case .invalidRequestMethod:
                    let reason = NSLocalizedString("Invalid request HTTP method.", comment: "The localized error description returned when a URLRequest has invalid or nil HTTP method")
                    return (reason, nil)
            }
        }
        
        public var failureReason: String? {
            
            return self.expand().failureReason
        }
        
        public var recoverySuggestion: String? {
            
            return self.expand().recoverySuggestion
        }
    }
}
