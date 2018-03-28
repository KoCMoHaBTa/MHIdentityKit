//
//  GrantType.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/25/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

public enum GrantType: String {
    
    case password = "password"
    case refreshToken = "refresh_token"
    case clientCredentials = "client_credentials"
    case authorizationCode = "authorization_code"
}
