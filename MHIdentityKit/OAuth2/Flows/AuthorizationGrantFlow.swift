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
    
    ///notify that authentication will begin
    func willAuthenticate() {
        
        NotificationCenter.default.post(name: .AuthorizationGrantFlowWillAuthenticate, object: self, userInfo: nil)
    }
    
    ///notify that authentication has finished
    func didFinishAuthenticating(with accessTokenResponse: AccessTokenResponse?, error: Error?) {
        
        var userInfo = [AnyHashable: Any]()
        userInfo[AccessTokenResponseUserInfoKey] = accessTokenResponse
        userInfo[ErrorUserInfoKey] = error
        
        if error == nil {
            
            NotificationCenter.default.post(name: .AuthorizationGrantFlowDidAuthenticate, object: self, userInfo: userInfo)
        }
        else {
            
            NotificationCenter.default.post(name: .AuthorizationGrantFlowDidFailToAuthenticate, object: self, userInfo: userInfo)
        }
    }
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
            networkClient.perform(request: request, handler: { (response) in
                
                do {
                    
                    let accessTokenResponse = try AccessTokenResponseHandler().handle(response: response)
                    
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
