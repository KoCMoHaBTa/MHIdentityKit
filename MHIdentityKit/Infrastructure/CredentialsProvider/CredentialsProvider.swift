//
//  CredentialsProvider.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 4/12/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///A type that provides credentials
public protocol CredentialsProvider {
    
    ///Provides credentials in an asynchronous manner. Can be implemented in a way to show a login screen.
    func credentials() async -> (username: String, password: String)
    
    ///(Optional) Called to notify the receiver that authentication has been successful with the suplied credentials.
    func didFinishAuthenticating()
    
    ///(Optional) Called to notify the receiver that authentication has failed with the suplied credentials
    func didFailAuthenticating(with error: Error)
}

extension CredentialsProvider {
    
    public func didFinishAuthenticating() {}
    public func didFailAuthenticating(with error: Error) {}
}
