//
//  NetworkClient.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 4/12/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///A type that performs network requests
public protocol NetworkClient {
    
    ///Performs a request and execute a completion handler when it is done
    func perform(request: URLRequest, handler: @escaping (Data?, URLResponse?, Error?) -> Void)
}

