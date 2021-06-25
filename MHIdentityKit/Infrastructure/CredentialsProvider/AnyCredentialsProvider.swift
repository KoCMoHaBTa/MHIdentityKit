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
    
    public typealias CredentialsHandler = () async -> (username: String, password: String)
    public typealias DidFinishAuthenticatingHandler = () -> Void
    public typealias DidFailAuthenticatingHandler = (_ error: Error) -> Void
    
    private let credentialsHandler: CredentialsHandler
    private let didFinishAuthenticatingHandler: DidFinishAuthenticatingHandler?
    private let didFailAuthenticatingHandler: DidFailAuthenticatingHandler?
    
    public init(credentialsHandler: @escaping CredentialsHandler, didFinishAuthenticatingHandler: DidFinishAuthenticatingHandler? = nil, didFailAuthenticatingHandler: DidFailAuthenticatingHandler? = nil) {
        
        self.credentialsHandler = credentialsHandler
        self.didFinishAuthenticatingHandler = didFinishAuthenticatingHandler
        self.didFailAuthenticatingHandler = didFailAuthenticatingHandler
    }
    
    public init(username: String, password: String, didFinishAuthenticatingHandler: DidFinishAuthenticatingHandler? = nil, didFailAuthenticatingHandler: DidFailAuthenticatingHandler? = nil) {
        
        self.credentialsHandler = { (username, password) }
        self.didFinishAuthenticatingHandler = didFinishAuthenticatingHandler
        self.didFailAuthenticatingHandler = didFailAuthenticatingHandler
    }
    
    public init(other credentialsProvider: CredentialsProvider) {
        
        self.credentialsHandler = credentialsProvider.credentials
        self.didFinishAuthenticatingHandler = credentialsProvider.didFinishAuthenticating
        self.didFailAuthenticatingHandler = credentialsProvider.didFailAuthenticating
    }
    
    //MARK: - CredentialsProvider
    
    public func credentials() async -> (username: String, password: String) {
        
        await credentialsHandler()
    }
    
    public func didFinishAuthenticating() {
        
        didFinishAuthenticatingHandler?()
    }
    
    public func didFailAuthenticating(with error: Error) {
        
        didFailAuthenticatingHandler?(error)
    }
}

extension CredentialsProvider where Self == AnyCredentialsProvider {
    
    public static func any(credentialsHandler: @escaping Self.CredentialsHandler, didFinishAuthenticatingHandler: Self.DidFinishAuthenticatingHandler? = nil, didFailAuthenticatingHandler: Self.DidFailAuthenticatingHandler? = nil) -> Self {
        
        .init(
            credentialsHandler: credentialsHandler,
            didFinishAuthenticatingHandler: didFinishAuthenticatingHandler,
            didFailAuthenticatingHandler: didFailAuthenticatingHandler
        )
    }
    
    public static func any(username: String, password: String, didFinishAuthenticatingHandler: Self.DidFinishAuthenticatingHandler? = nil, didFailAuthenticatingHandler: Self.DidFailAuthenticatingHandler? = nil) -> Self {
        
        .init(
            username: username,
            password: password,
            didFinishAuthenticatingHandler: didFinishAuthenticatingHandler,
            didFailAuthenticatingHandler: didFailAuthenticatingHandler
        )
    }
}
