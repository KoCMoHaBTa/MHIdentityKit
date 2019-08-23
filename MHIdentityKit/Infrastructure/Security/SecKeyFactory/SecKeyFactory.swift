//
//  SecKeyFactory.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 22.08.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation

///A type that can easily create SecKey instances. Varios factory methods and initializers are defined as extension
public protocol SecKeyFactory {
    
}

extension SecKey: SecKeyFactory {}

