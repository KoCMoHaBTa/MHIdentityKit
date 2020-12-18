//
//  MHIdentityKitError.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/22/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

public enum MHIdentityKitError: LocalizedError {
    
    case wrapped(error: Error)
    case general(description: String, reason: String?)
    case authorizationFailed(reason: LocalizedError)
    case authenticationFailed(reason: LocalizedError)
    case publicKeyCreationFailed(reason: LocalizedError)
    case signatureVerificationFailed(reason: LocalizedError)
    
    init(error: Error) {
        
        self = .wrapped(error: error)
    }
    
    private func expand() -> (errorDescription: String?, failureReason: String?, recoverySuggestion: String?) {
        
        switch self {
            
            case .wrapped(let error):
                let error = error as NSError
                return (error.localizedDescription, error.localizedFailureReason, nil)
            
            case .general(let description, let reason):
                return (description, reason, nil)
            
            case .authorizationFailed(let reason):
                
                let description = NSLocalizedString("Unable to authorize the request", comment: "The error desciption when a request cannot be authorized")
                return (description, reason.failureReason, reason.recoverySuggestion)
            
            case .authenticationFailed(let reason):
                
                let description = NSLocalizedString("Unable to authenticate the client", comment: "The localized error desciption when client authentication fails")
                return (description, reason.failureReason, reason.recoverySuggestion)
            
            case .publicKeyCreationFailed(let reason):
                let description = NSLocalizedString("Unable to create RSA Public key.", comment: "The error description when creating RSA public key has failed and no system error has been thrown.")
                return (description, reason.failureReason, reason.recoverySuggestion)
            
            case .signatureVerificationFailed(let reason):
                let description = NSLocalizedString("Unable to verify digital signature.", comment: "The error description when verifying a digital signature has failed, eg when verifying an id token.")
                return (description, reason.failureReason, reason.recoverySuggestion)
            
        }
    }
    
    public func contains<E: Error>(error: E.Type) -> Bool {
    
        switch self {
            
            case .wrapped(let error):
                return error is E || (error as? MHIdentityKitError)?.contains(error: E.self) == true
            
            case .general:
                return false
            
            case .authorizationFailed(let reason):
                return reason is E || (reason as? MHIdentityKitError)?.contains(error: E.self) == true
            
            case .authenticationFailed(let reason):
                return reason is E || (reason as? MHIdentityKitError)?.contains(error: E.self) == true
            
            case .publicKeyCreationFailed(let reason):
                return reason is E || (reason as? MHIdentityKitError)?.contains(error: E.self) == true
            
            case .signatureVerificationFailed(let reason):
                return reason is E || (reason as? MHIdentityKitError)?.contains(error: E.self) == true
        }
    }
    
    //MARK: - LocalizedError
    
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
        case unknown
        
        case clientNotAuthenticated
        case tokenExpired
        case buildAuthenticationHeaderFailed
        case unknownURLResponse
        
        @available(*, deprecated, message: "Not thrown from framework anymore. Replcaed by `invalidAccessTokenResponse`.") case unableToParseAccessToken
        
        @available(*, deprecated, message: "Not thrown from framework anymore. Replcaed by `invalidAccessTokenResponse`.") case unableToParseData
        case unknownHTTPResponse(code: Int)
        
        case invalidRequestURL
        case invalidContentType
        case invalidRequestMethod
        case invalidAccessTokenResponse
        case invalidAuthorizationResponse
        
        case typeMismatch(expected: String, actual: String)
        case invalidCertificate
        
        case unableToCreateSecurityTransform
        case unableToSetSecurityTransformAttributes
        case unableToExecuteSecurityTransform
        
        case invalidIDToken(reason: IDTokenValidationError)
        
        private func expand() -> (failureReason: String?, recoverySuggestion: String?) {
            
            switch self {
                
                case .general(let message):
                    return (message, nil)
                
                case .unknown:
                    return (nil, nil)
                
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
                
                case .unableToParseAccessToken, .unableToParseData:
                    return (nil, nil)
                
                case .unknownHTTPResponse(let code):
                    let format = NSLocalizedString("Unknown HTTP response with code: %@", comment: "The localized error description returned when the response code is not sucess 2xx and no other has been handled")
                    let reason = String(format: format, "\(code)")
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
                
                case .invalidAccessTokenResponse:
                    let reason = NSLocalizedString("The received access token response is not valid.", comment: "The localized error description returned when a received access token response is not valid due to incorrect or malformed data.")
                    return (reason, nil)
                
                case .invalidAuthorizationResponse:
                    let reason = NSLocalizedString("The received authorization token response is not valid.", comment: "The localized error description returned when a received authorization token response is not valid due to incorrect or malformed data.")
                    return (reason, nil)
                
                case .typeMismatch(let expected, let actual):
                    let reasonFormat = NSLocalizedString("Expected <%@> type, but got <%@> type instead.>", comment: "The error reason format when, eg. creating RSA public key, has failed due to type mismatch.")
                    let reason = String(format: reasonFormat, expected, actual)
                    return (reason, nil)
                
                case .invalidCertificate:
                    let reason = NSLocalizedString("The certificate is not valid.", comment: "The localized error reason returned when an invalid certificate is the cause of the error.")
                    return (reason, nil)
                
                case .unableToCreateSecurityTransform:
                    let reason = NSLocalizedString("Unable to create security transform.", comment: "The localized error reason returned when a security transform cannot be created, eg. whe verifiying an id token.")
                    return (reason, nil)
                
                case .unableToSetSecurityTransformAttributes:
                    let reason = NSLocalizedString("Unable to set attributes to security  transform.", comment: "The localized error reason returned when cannot set one or more attributes to a security transform, eg. whe verifiying an id token.")
                    return (reason, nil)
                
                case .unableToExecuteSecurityTransform:
                    let reason = NSLocalizedString("Unable to execute security transform.", comment: "The localized error reason returned when a security transform cannot be executed, eg. whe verifiying an id token.")
                    return (reason, nil)
                    
                case .invalidIDToken(let reason):
                    return reason.expand()
            }
        }
        
        public var failureReason: String? {
            
            return self.expand().failureReason
        }
        
        public var recoverySuggestion: String? {
            
            return self.expand().recoverySuggestion
        }
    }
    
    public enum IDTokenValidationError: LocalizedError {
        
        case invalidIssuer
        case invalidAudience
        case invalidAuthorizedParty
        
        fileprivate func expand() -> (failureReason: String?, recoverySuggestion: String?) {
            
            switch self {
                
                case .invalidIssuer:
                    let reason = NSLocalizedString("Invalid ID Token: Issuer identifier claim (iss) does not match.", comment: "The error reason when validation of ID token fails due to invalid issuer.")
                    return (reason, nil)
                    
                case .invalidAudience:
                    let reason = NSLocalizedString("Invalid ID Token: Audience claim (aud) do not match with client_id or contains untrusted values", comment: "The error reason when validation of ID token fails due to invalid audience.")
                    return (reason, nil)
                    
                case .invalidAuthorizedParty:
                    let reason = NSLocalizedString("Invalid ID Token: Authorized party claim (azp) do not match with client_id or is missing.", comment: "The error reason when validation of ID token fails due to invalid authorized party.")
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
