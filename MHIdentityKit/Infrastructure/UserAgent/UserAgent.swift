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
     Performs a request within the user agent and execute a redirectionHandler when a redirection occurs for a given or default redirect URL.
     
     - parameter request: The request to be performed by the user agent.
     - parameter redirectURI: The redirect URL provided by the client.
     - parameter redirectionHandler: The handler to be called when a redirection occur for the specified `redirectURI`. The handler takes as argument the redirect `URLRequest` and returns boolean value that indicates whenver the redirect request has been successfully handled. An error is thrown if the redirect request is an [error response](https://tools.ietf.org/html/rfc6749#section-4.1.2.1)
     
     - important: Because the `redirectURI` is optional in the context of the client flow, when that is the case, the user agent is responsible to pass the correct rediction request to the `redirectionHandler`. Such case may occur when the server provides the ability to define a default `redirectURI` that will be used when none is provided in the flow. In case the `redirectURI` is provided, the user agent should pass the correct rediction request based on the `redirectURI`.
     
     - important: Since it is possible that multiple redirections may occur. If the returned value of `redirectionHandler` is `false` - this means that the redirection has not been handled and the user agent should continue. If the returned value is `true` - this means that the redirection has been handled and the user agent should complete.
     
     - note: In the context of `AuthorizationCodeGrantFlow` - a redirectin is handled if it matches the [Authorization Response specifications](https://tools.ietf.org/html/rfc6749#section-4.1.2). In that case the web browser should be closed after which an access token rquest is issued.
     
     */
    
    func perform(_ request: URLRequest, redirectURI: URL?, redirectionHandler: @escaping (URLRequest) throws -> Bool)
}
