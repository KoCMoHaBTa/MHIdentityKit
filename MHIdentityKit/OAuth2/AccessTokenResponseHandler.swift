//
//  AccessTokenResponseHandler.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 6/1/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

//https://tools.ietf.org/html/rfc6749#section-5.1
//https://tools.ietf.org/html/rfc6749#section-5.2

///Handles an HTTP response in attempt to produce an access token or error as defined
public struct AccessTokenResponseHandler {
    
    public init() {
        
    }
    
    public func handle(response networkResponse: NetworkResponse) throws -> AccessTokenResponse {
        
        //if response is unknown - throw an error
        guard let response = networkResponse.response as? HTTPURLResponse else {
            
            throw MHIdentityKitError.Reason.unknownURLResponse
        }
        
        let data = networkResponse.data
        
        //parse the data
        guard
        let parameters = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        else {
            
            throw MHIdentityKitError.Reason.invalidAccessTokenResponse
        }
        
        //if the error is one of the defined in the OAuth2 framework - throw it
        if let error = OAuth2Error(parameters: parameters) {
            
            throw error
        }
        
        //make sure the response code is success 2xx
        guard (200..<300).contains(response.statusCode) else {
            
            throw MHIdentityKitError.Reason.unknownHTTPResponse(code: response.statusCode)
        }
        
        //parse the access token
        guard
        let accessTokenResponse = try? AccessTokenResponse(parameters: parameters)
        else {
            
            throw MHIdentityKitError.Reason.invalidAccessTokenResponse
        }
        
        return accessTokenResponse
    }
}
