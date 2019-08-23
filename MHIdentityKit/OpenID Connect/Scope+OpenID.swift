//
//  Scope+OpenID.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 14.07.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation

extension Scope {
    
    static let openid: Scope = "openid"
    
    public func addingOpenIDScopeIfNeeded() -> Scope {
        
        var components = self.components
        if components.contains(Scope.openid.value) {
            
            return self
        }
        
        components.append(Scope.openid.value)
        
        return Scope(components: components)
    }
}
