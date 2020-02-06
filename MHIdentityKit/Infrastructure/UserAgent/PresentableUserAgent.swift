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
    public var presentationHandler: (T) -> Void
    public var dismissHandler: (T) -> Void
    
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
    
    public func perform(_ request: URLRequest, redirectURI: URL?, redirectionHandler: @escaping (URLRequest) throws -> Bool) {
        
        DispatchQueue.main.async {
            
            self.userAgent.perform(request, redirectURI: redirectURI, redirectionHandler: { (request) -> Bool in
                
                let didHandleRedirect = try redirectionHandler(request)
                
                if didHandleRedirect {
                    
                    self.dismiss()
                }
                
                return didHandleRedirect
            })
            
            self.present()
        }
    }
    
    public func present() {
        
        self.presentationHandler(self.userAgent)
    }
    
    public func dismiss() {
        
        self.dismissHandler(self.userAgent)
    }
}
