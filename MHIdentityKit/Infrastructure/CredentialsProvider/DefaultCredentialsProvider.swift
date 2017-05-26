//
//  DefaultCredentialsProvider.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/26/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///A default implementation of credentials provider, used internally
struct DefaultCredentialsProvider: CredentialsProvider {
    
    private let username: String
    private let password: String
    
    init(username: String, password: String) {
        
        self.username = username
        self.password = password
    }
    
    func credentials(handler: @escaping (CredentialsProvider.Username, CredentialsProvider.Password) -> Void) {
        
        handler(self.username, self.password)
    }
}
