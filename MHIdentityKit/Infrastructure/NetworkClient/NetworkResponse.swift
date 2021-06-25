//
//  NetworkResponse.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 6/5/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

public struct NetworkResponse {
    
    public var data: Data
    public var response: URLResponse
    
    public init(data: Data, response: URLResponse) {
        
        self.data = data
        self.response = response
    }
}
