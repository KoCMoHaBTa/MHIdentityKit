//
//  AuthorizationGrantFlow.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 4/11/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

//A type that performs an authorization grant flow.
//The conforming type is in charge of all details related to a particular flow, including management of the state of access and refresh tokens and the cooridnation of any client specific actions, eg delegating UI presentations.
public protocol AuthorizationGrantFlow {
    
    associatedtype Response
    
    /**
     Executes the flow that authenticates the user and upon success returns an access token that can be used to authorize client's requests
     
     - parameter handler: The callback, executed when the authentication is complete. The callback takes 2 arguments - a Token and an Error
     */
    func authenticate(handler: @escaping (Response?, Error?) -> Void)
    
    /**
     Authorizes an instance of URLRequest.
     
     Upon success, in the callback handler, the provided request will be authorized, otherwise the original request will be provided.
     
     - parameter request: The request to authorize.
     - parameter handler: The callback, executed when the authorization is complete. The callback takes 2 arguments - an URLRequest and an Error
     */
    func authorize(request: URLRequest, handler: @escaping (URLRequest, Error?) -> Void)
}





//AuthorizationCode
//Implicit
//ResourceOwnerPasswordCredentials
//ClientCredentials

//func build(service: IdentityService, completion: (error: NSError?) -> Void)
//func execute(service: IdentityService, completion: (error: NSError?) -> Void)
//func verify(service: IdentityService, completion: (succeeded: Bool, error: NSError?) -> Void)
//func authenticate(service: IdentityService, completion: (error: NSError?) -> Void)
//func complete(service: IdentityService, error: NSError?)



class Controller {
    
    func test() {
        
        let url = URL(string: "https://api-vapt-int.onebigsplash.com/feed/newsfeed")!
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
        }
        
        task.resume()
    }
}
