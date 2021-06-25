//
//  PresentableUserAgent.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 6.02.20.
//  Copyright © 2020 Milen Halachev. All rights reserved.
//

import Foundation


///A type that makes a given user agent persentable.
public struct PresentableUserAgent<T: UserAgent>: UserAgent {
    
    public var userAgent: T
    public var presentationHandler: (T) async -> Void
    public var dismissHandler: (T) async -> Void
    
    /**
    Makes a presentable UserAgent of a given user agent.

    - parameter userAgent: The user agent to present.
    - parameter presentationHandler: This is the presentation handler. Called when the user agent has to be shown on screen.
    - parameter dismissHandler: This is the dimiss handler. Called when the user agent successfully handles a redirect and has to be dismissed.

    - note: If the user agent is UIViewController, It is recommended embed it into UINavigationController with visible toolbar, because it contains web navigation controls. If you present it modally within an UINavigationController - it is your responsibility to setup a cancel/close button, based on your needs.
    */
    
    public init(_ userAgent: T, presentationHandler: @escaping (T) -> Void, dismissHandler: @escaping (T) -> Void) {
        
        self.userAgent = userAgent
        self.presentationHandler = presentationHandler
        self.dismissHandler = dismissHandler
    }
    
    public func present() async {
        
        await presentationHandler(userAgent)
    }
    
    public func dismiss() async {
        
        await dismissHandler(userAgent)
    }
    
    //MARK: - UserAgent
    
    public func perform(_ request: URLRequest, redirectURI: URL) async -> URLRequest? {
        
        await present()
        return await userAgent.perform(request, redirectURI: redirectURI)
    }
    
    public func finish(with error: Error?) async {
        
        await userAgent.finish(with: error)
        await dismissHandler(userAgent)
    }
}
