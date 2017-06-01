//
//  BearerAccessTokenAuthorizer.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/26/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

//https://tools.ietf.org/html/rfc6750#section-2

///Authorizes a request using a bearer access token
public struct BearerAccessTokenAuthorizer: RequestAuthorizer {
    
    public let token: String
    public let method: AuthorizationMethod
    
    public func authorize(request: URLRequest, handler: @escaping (URLRequest, Error?) -> Void) {
        
        var request = request
        var error: Error? = nil
        
        defer {
            
            handler(request, error)
        }
        
        switch self.method {
            
            case .header:
                request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
            
            case .body:
                
                //make sure the request content type is correct
                guard request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded" else {
                    
                    error = MHIdentityKitError.authorizationFailed(reason: MHIdentityKitError.Reason.invalidContentType)
                    return
                }
            
                //make sure the request method is supported
                guard let method = request.httpMethod, method != "GET" else {
                
                    error = MHIdentityKitError.authorizationFailed(reason: MHIdentityKitError.Reason.invalidRequestMethod)
                    return
                }
                
                //TODO: Add body validation
            
                var body = ""
            
                //if there is body - load it
                if let data = request.httpBody,
                let string = String(data: data, encoding: .utf8) {
                    
                    body = string + "&"
                }
            
                //add the parameter at the end of the body
                body = body + ["access_token": self.token].urlEncodedParametersString
            
                //update the request
                request.httpBody = body.data(using: .utf8)
            
            case .query:
                
                //make sure the request has an URL
                guard let url = request.url else {
                    
                    error = MHIdentityKitError.authorizationFailed(reason: MHIdentityKitError.Reason.invalidRequestURL)
                    return
                }
                
                var urlString = url.absoluteString
            
                //if there is no query - start by adding '?'
                if url.query == nil {
                    
                    urlString = urlString + "?"
                }
            
                //a the parameter
                urlString = urlString + "&" + ["access_token": self.token].urlEncodedParametersString
            
                //update the request URL
                request.url = URL(string: urlString)
        }
    }
}

extension BearerAccessTokenAuthorizer {
    
    public enum AuthorizationMethod {
        
        //https://tools.ietf.org/html/rfc6750#section-2.1
        case header
        
        //https://tools.ietf.org/html/rfc6750#section-2.2
        case body
        
        //https://tools.ietf.org/html/rfc6750#section-2.3
        case query
    }
}
