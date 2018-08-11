//
//  AnyCredentialsProvider.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 11.08.18.
//  Copyright © 2018 Milen Halachev. All rights reserved.
//

import Foundation

///A default, closure based implementation of CredentialsProvider
public struct AnyCredentialsProvider: CredentialsProvider {
    
    public let handler: (_ handler: @escaping (CredentialsProvider.Username, CredentialsProvider.Password) -> Void) -> Void
    
    public init(handler: @escaping (_ handler: @escaping (CredentialsProvider.Username, CredentialsProvider.Password) -> Void) -> Void) {
        
        self.handler = handler
    }
    
    public init(other credentialsProvider: CredentialsProvider) {
        
        self.handler = { handler in
            
            credentialsProvider.credentials(handler: handler)
        }
    }
    
    public func credentials(handler: @escaping (CredentialsProvider.Username, CredentialsProvider.Password) -> Void) {
        
        self.handler(handler)
    }
}
