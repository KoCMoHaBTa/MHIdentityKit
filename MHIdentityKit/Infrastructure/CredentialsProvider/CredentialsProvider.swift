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
    
    typealias Username = String
    typealias Password = String
    
    func credentials(handler: @escaping (Username, Password) -> Void)
}


