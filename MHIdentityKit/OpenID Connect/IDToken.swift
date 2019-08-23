//
//  IDToken.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 15.07.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation

//https://openid.net/specs/openid-connect-core-1_0.html#IDToken
public struct IDToken: RawRepresentable {
    
//    public let iss: String
//    public let sub: String
//    public let aud: String
    
    //MARK: - RawRepresentable
    
    public let rawValue: String
    
    public init?(rawValue: String) {
        
        self.rawValue = rawValue
    }
}
