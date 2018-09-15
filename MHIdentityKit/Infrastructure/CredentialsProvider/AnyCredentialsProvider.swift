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
    
    private let credentialsHandler: (_ handler: @escaping (CredentialsProvider.Username, CredentialsProvider.Password) -> Void) -> Void
    private let didFinishAuthenticatingHandler: (() -> Void)?
    private let didFailAuthenticatingHandler: ((Error) -> Void)?
    
    public init(credentialsHandler: @escaping (_ handler: @escaping (CredentialsProvider.Username, CredentialsProvider.Password) -> Void) -> Void) {
        
        self.init(credentialsHandler: credentialsHandler, didFinishAuthenticatingHandler: nil, didFailAuthenticatingHandler: nil)
    }
    
    public init(credentialsHandler: @escaping (_ handler: @escaping (CredentialsProvider.Username, CredentialsProvider.Password) -> Void) -> Void, didFinishAuthenticatingHandler: (() -> Void)?, didFailAuthenticatingHandler: ((Error) -> Void)?) {
        
        self.credentialsHandler = credentialsHandler
        self.didFinishAuthenticatingHandler = didFinishAuthenticatingHandler
        self.didFailAuthenticatingHandler = didFailAuthenticatingHandler
    }
    
    public init(other credentialsProvider: CredentialsProvider) {
        
        self.credentialsHandler = credentialsProvider.credentials
        self.didFinishAuthenticatingHandler = credentialsProvider.didFinishAuthenticating
        self.didFailAuthenticatingHandler = credentialsProvider.didFailAuthenticating
    }
    
    public init(username: Username, password: Password) {
        
        self.init(username: username, password: password, didFinishAuthenticatingHandler: nil, didFailAuthenticatingHandler: nil)
    }
    
    public init(username: Username, password: Password, didFinishAuthenticatingHandler: (() -> Void)?, didFailAuthenticatingHandler: ((Error) -> Void)?) {
        
        self.credentialsHandler = { handler in
            
            handler(username, password)
        }
        
        self.didFinishAuthenticatingHandler = didFinishAuthenticatingHandler
        self.didFailAuthenticatingHandler = didFailAuthenticatingHandler
    }
    
    //MARK: - CredentialsProvider
    
    public func credentials(handler: @escaping (CredentialsProvider.Username, CredentialsProvider.Password) -> Void) {
        
        self.credentialsHandler(handler)
    }
    
    public func didFinishAuthenticating() {
        
        self.didFinishAuthenticatingHandler?()
    }
    
    public func didFailAuthenticating(with error: Error) {
        
        self.didFailAuthenticatingHandler?(error)
    }
}
