//
//  JWT.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 19.07.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation
import Security

public struct JWT: RawRepresentable {
    
    public let type: JWTType
    public let header: [String: Any]
    public let claims: [String: Any]
    
    //MARK: - RawRepresentable
    
    public let rawValue: String
    
    //https://tools.ietf.org/html/draft-ietf-oauth-json-web-token-32#section-7.2
    public init?(rawValue: String) {
        
        guard rawValue.contains(".") else {
            
            return nil
        }
        
        let segments = rawValue.components(separatedBy: ".")
        guard segments.count > 1 else {
            
            return nil
        }
        
        guard
        let headerData = Data(base64UrlEncoded: segments[0]),
        let header = try? JSONSerialization.jsonObject(with: headerData, options: []) as? [String: Any]
        else {
            
            return nil
        }
        
        guard let type = JWTType(jwt: rawValue) else {
            
            return nil
        }
        
        let messageData: Data
        let message: String
        
        switch type {
            
            case .JWS:
                
                /*
                 If the JWT is a JWS, follow the steps specified in [JWS] for
                 validating a JWS.  Let the Message be the result of base64url
                 decoding the JWS Payload.
                 */
                
                guard
                let payloadData = Data(base64UrlEncoded: segments[1]),
                let payload = String(data: payloadData, encoding: .utf8)
                else {
                    
                    return nil
                }
                
                messageData = payloadData
                message = payload
            
            case .JWE:
                //JWE is not yet supported
                return nil
        }
        
        /*
         8.   If the JOSE Header contains a "cty" (content type) value of
         "JWT", then the Message is a JWT that was the subject of nested
         signing or encryption operations.  In this case, return to Step
         1, using the Message as the JWT.
         */
        
        if header["cty"] as? String == "JWT" {
            
            guard let jwt = JWT(rawValue: message) else {
                
                return nil
            }
            
            self = jwt
            return
        }
        
        guard let claims = try? JSONSerialization.jsonObject(with: messageData, options: []) as? [String: Any] else {
            
            return nil
        }

        self.rawValue = rawValue
        self.type = type
        self.header = header
        self.claims = claims
    }
    
    public func verify(using verifier: SignatureVerifier) throws {

        switch self.type {
            
            case .JWS:
                let segments = self.rawValue.components(separatedBy: ".")
                guard
                let input = (segments[0] + "." + segments[1]).data(using: .utf8),
                let signature = Data(base64UrlEncoded: segments[2])
                else {
                    
                    throw MHIdentityKitError.signatureVerificationFailed(reason: MHIdentityKitError.Reason.unknown)
                }
                
                try verifier.verify(input: input, withSignature: signature)
            
            case .JWE:
                //not supported
                throw MHIdentityKitError.signatureVerificationFailed(reason: MHIdentityKitError.Reason.typeMismatch(expected: "JWT token", actual: "JWE token"))
        }
    }
}
