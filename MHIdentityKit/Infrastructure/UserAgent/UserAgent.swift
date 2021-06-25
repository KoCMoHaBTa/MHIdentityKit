//
//  UserAgent.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 27.03.18.
//  Copyright © 2018 Milen Halachev. All rights reserved.
//

import Foundation

///A type that represents a resource owner's user agent (typically a web browser) and is capable of receiving incoming requests (via redirection) from the authorization server.
public protocol UserAgent {
    
    /**
     Performs a request within the user agent and returns the redirect request that matches the redirect URI.
     
     - parameter request: The request to be performed by the user agent.
     - parameter redirectURI: The redirect URL provided by the client.
     - returns: The redirect URLRequest, that matches the redirectURI or `nil` if the user agent has been cancelled, eg when the user closes the browser.
     - note: Returning `nil` from this method will instruct the caller that it should cancel the authorization process. 
     */
    func perform(_ request: URLRequest, redirectURI: URL) async -> URLRequest?
    
    /**
     Called when the redirect request has finshed processing.
     
     - parameter error: An optional `Error` if the redirect request processing has failed.
     - note: When this method is called, the user agent should return the user to the application.
     */
    func finish(with error: Error?) async
}



//- parameter redirectionHandler: The handler to be called when a redirection occur for the specified `redirectURI`. The handler takes as argument the redirect `URLRequest` and returns boolean value that indicates whenver the redirect request has been successfully handled. An error is thrown if the redirect request is an [error response](https://tools.ietf.org/html/rfc6749#section-4.1.2.1)
//- note: In the context of `AuthorizationCodeGrantFlow` - a redirecting is handled if it matches the [Authorization Response specifications](https://tools.ietf.org/html/rfc6749#section-4.1.2). In that case the web browser should be closed after which an access token rquest is issued.
