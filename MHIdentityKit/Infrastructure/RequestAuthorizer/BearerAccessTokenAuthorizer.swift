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
    
    public var token: String
    public var method: AuthorizationMethod
    
    public init(token: String, method: AuthorizationMethod) {
        
        self.token = token
        self.method = method
    }
    
    public func authorize(request: URLRequest) async throws -> URLRequest {
        
        var request = request
        
        switch self.method {
            
            case .header:
                request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
                return request
            
            case .body:
                
                //make sure the request content type is correct
                guard request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded" else {
                    
                    throw Error.invalidContentType
                }
            
                //make sure the request method is supported
                guard let method = request.httpMethod, method != "GET" else {
                
                    throw Error.invalidRequestMethod
                }
                
                //TODO: Add body validation
            
                var body = ""
            
                //if there is body - load it
                if let data = request.httpBody,
                let string = String(data: data, encoding: .utf8),
                string.isEmpty == false {
                    
                    body = string + "&"
                }
            
                //add the parameter at the end of the body
                body = body + ["access_token": self.token].urlEncodedParametersString
            
                //update the request
                request.httpBody = body.data(using: .utf8)
                return request
            
            case .query:
                
                //make sure the request has an URL
                guard
                let url = request.url,
                var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
                else {
                    
                    throw Error.invalidRequestURL
                }
                
                var query = components.query ?? ""
                
                if query.isEmpty == false {
                    
                    query = query + "&"
                }
                
                query = query + "access_token=\(self.token)"
                components.query = query
                
            
                //update the request URL
                request.url = components.url
                return request
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

extension RequestAuthorizer where Self == BearerAccessTokenAuthorizer {
    
    public static func bearer(token: String, method: Self.AuthorizationMethod = .header) -> Self {
        
        .init(token: token, method: method)
    }
}

extension BearerAccessTokenAuthorizer {
    
    enum Error: Swift.Error {
        
        ///Indicates that the Content-Type header is not valid
        ///For body authorization - this should be `application/x-www-form-urlencoded`
        case invalidContentType
        
        ///Indicates that the request method is not valid
        ///For body authorization - this should be different from GET
        case invalidRequestMethod
        
        ///Indicates that the request URL is invalid or missing
        case invalidRequestURL
    }
}
