//
//  AccessTokenResponse.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/24/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

//https://tools.ietf.org/html/rfc6749#section-5.1
public struct AccessTokenResponse {
    
    public var accessToken: String
    public var tokenType: String
    public var expiresIn: TimeInterval?
    public var refreshToken: String?
    public var scope: Scope?
    
    init(accessToken: String, tokenType: String, expiresIn: TimeInterval?, refreshToken: String?, scope: Scope?) {
        
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.refreshToken = refreshToken
        self.scope = scope
    }
    
    ///The date when this object has been created - used to determine whenever the access token has expired
    private let responseCreationDate = Date()
    
    ///determine whenever the access token has expired
    public var isExpired: Bool {
        
        //if expiration time interval is not provided - call the expiration handler
        guard let expiresIn = self.expiresIn else {
            
            return type(of: self).expirationHandler(self)
        }
        
        //compare the time interval since the creation of this object with the expiration time interval provided
        let timeIntervalPassed = Date().timeIntervalSince(self.responseCreationDate)
        return timeIntervalPassed >= expiresIn
    }
    
    init?(json: [String: Any]) {
        
        guard
        let accessToken = json["access_token"] as? String,
        let tokenType = json["token_type"] as? String
        else {
            
            return nil
        }
        
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.expiresIn = json["expires_in"] as? TimeInterval
        self.refreshToken = json["refresh_token"] as? String
        
        if let scopeRawValue = json["scope"] as? String {
            
            self.scope = Scope(rawValue: scopeRawValue)
        }
        else {
            
            self.scope = nil
        }
    }
}

extension AccessTokenResponse {
    
    ///Provide a custom expiration handler in case the server does not return the expiration time interval.
    ///-returns: true if the token is expired, otherwise false. Default behaviour returns false.
    public static var expirationHandler: (AccessTokenResponse) -> Bool = { _ in
        
        //the authorization server SHOULD provide the expiration time via other means or document the default value.
        //Assume the token has not expired. In case it is - the failure of the request will indicate that the token is invalid, that should result in retry from client perspective.
        return false
    }
}
