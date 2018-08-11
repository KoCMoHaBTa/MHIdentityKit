//
//  DefaultNetoworkClient.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/26/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

#if os(iOS)
    import UIKit
#endif

///A default implementation of a NetworkClient, used internally
class DefaultNetoworkClient: NetworkClient {
    
    private let session = URLSession(configuration: .ephemeral)
    
    func perform(_ request: URLRequest, completion: @escaping (NetworkResponse) -> Void) {
        
        #if os(iOS)
            let application = UIApplication.shared
            var id = UIBackgroundTaskInvalid
            id = application.beginBackgroundTask(withName: "MHIdentityKit.DefaultNetoworkClient.\(#function).backgroundTask") {
                
                let description = NSLocalizedString("Unable to complete network request", comment: "The description of the network error produced when the background time has expired")
                let reason = NSLocalizedString("Backgorund time has expired.", comment: "The reason of the network error produced when the background time has expired")
                let error = MHIdentityKitError.general(description: description, reason: reason)
                
                completion(NetworkResponse(data: nil, response: nil, error: error))
                application.endBackgroundTask(id)
                id = UIBackgroundTaskInvalid
            }
        #endif
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            
            completion(NetworkResponse(data: data, response: response, error: error))
            
            #if os(iOS)
                application.endBackgroundTask(id)
                id = UIBackgroundTaskInvalid
            #endif
        }
        
        task.resume()
    }
    
    deinit {
        
        self.session.invalidateAndCancel()
    }
}

///The shared instance of the default network client, used internally
public let _defaultNetworkClient: NetworkClient = DefaultNetoworkClient()
