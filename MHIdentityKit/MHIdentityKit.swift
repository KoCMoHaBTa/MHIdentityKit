//
//  MHIdentityKit.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 4/11/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

let bundleIdentifier = Bundle(for: OAuth2IdentityManager.self).bundleIdentifier!

extension TimeInterval {
    
    init?(_ value: Any?) {
        
        if let value = value as? TimeInterval {
            
            self = value
            return
        }
        
        if let string = value as? String, let value = TimeInterval(string) {
            
            self = value
            return
        }
        
        return nil
    }
}
