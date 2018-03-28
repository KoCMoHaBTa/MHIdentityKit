//
//  AuthorizationResponseType.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 27.03.18.
//  Copyright © 2018 Milen Halachev. All rights reserved.
//

import Foundation

//https://tools.ietf.org/html/rfc6749#section-3.1.1
public enum AuthorizationResponseType: String {
    
    case code = "code"
    case token = "token"
}
