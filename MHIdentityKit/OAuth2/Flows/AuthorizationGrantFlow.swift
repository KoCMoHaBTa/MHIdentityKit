//
//  AuthorizationGrantFlow.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 4/11/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

//A type that performs an authorization grant flow in order to authenticate a client.
public protocol AuthorizationGrantFlow {
        
    /**
     Executes the flow that authenticates the user and upon success returns an access token that can be used to authorize client's requests
     
     - parameter handler: The callback, executed when the authentication is complete. The callback takes 2 arguments - a Token and an Error
     */
    func authenticate(handler: @escaping (AccessTokenResponse?, Error?) -> Void)
    
    @available(iOS 13, *)
    func authenticateAsync() async throws -> AccessTokenResponse?
}
