//
//  AccessTokenResponse+IDToken.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 15.07.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation

extension AccessTokenResponse {
    
    ///The ID Token raw value, when using an OpenID Connect flow
    var idToken: IDToken? {
        
        guard let rawValue = additionalParameters["id_token"] as? String else {
            
            return nil
        }
        
        guard let jwt = JWT(rawValue: rawValue) else {
            
            return nil
        }
        
        return IDToken(jwt: jwt)
    }
}
