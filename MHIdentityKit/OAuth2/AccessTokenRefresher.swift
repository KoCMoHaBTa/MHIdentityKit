//
//  AccessTokenRefresher.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/24/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///A type that refresh an access token using a refresh token
public protocol AccessTokenRefresher {
    
    func refresh(using requestModel: AccessTokenRefreshRequest) async throws -> AccessTokenResponse
}
