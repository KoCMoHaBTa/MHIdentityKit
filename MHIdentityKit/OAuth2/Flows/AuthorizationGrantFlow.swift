//
//  AuthorizationGrantFlow.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 4/11/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

//A type that performs an authorization grant flow in order to authenticate a client.
public protocol AuthorizationGrantFlow {
        
    /**
     Executes the flow that authenticates the user and upon success returns an access token that can be used to authorize client's requests
     
     - parameter handler: The callback, executed when the authentication is complete. The callback takes 2 arguments - a Token and an Error
     */
    func authenticate(handler: @escaping (AccessTokenResponse?, Error?) -> Void)
}

extension AuthorizationGrantFlow {
    
    ///Authorize and perform a request using a given authorizer and network client
    //This method exsist in order to reduce bilerplate code within flow implementations
    func authorizeAndPerform(request: URLRequest, using authoriser: RequestAuthorizer, and networkClient: NetworkClient, handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
        
        //authorize the request
        authoriser.authorize(request: request) { (request, error) in
            
            guard error == nil else {
                
                handler(nil, error)
                return
            }
            
            //perform the request
            networkClient.perform(request: request, handler: { (data, response, error) in
                
                do {
                    
                    let accessTokenResponse = try AccessTokenResponseHandler().handle(data: data, response: response, error: error)
                    
                    DispatchQueue.main.async {
                        
                        handler(accessTokenResponse, nil)
                    }
                }
                catch {
                    
                    DispatchQueue.main.async {
                        
                        handler(nil, error)
                    }
                }
            })
        }
    }
}
