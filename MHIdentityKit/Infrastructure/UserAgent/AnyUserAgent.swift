//
//  AnyUserAgent.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 4.08.18.
//  Copyright © 2018 Milen Halachev. All rights reserved.
//

import Foundation

///A default, closures based, implementation of UserAgent
public struct AnyUserAgent: UserAgent {
    
    public typealias PerformRequestHandler = (_ request: URLRequest, _ redirectURI: URL) async -> URLRequest?
    public typealias FinishHandler = (_ error: Error?) async -> Void
    
    public let performRequestHandler: PerformRequestHandler
    public let finishHandler: FinishHandler?
    
    public init(performRequestHandler: @escaping PerformRequestHandler, finishHandler: FinishHandler? = nil) {
        
        self.performRequestHandler = performRequestHandler
        self.finishHandler = finishHandler
    }
    
    public init(other userAgent: UserAgent) {
        
        self.init(
            performRequestHandler: userAgent.perform(_:redirectURI:),
            finishHandler: userAgent.finish(with:)
        )
    }
    
    //MARK: - UserAgent
    
    public func perform(_ request: URLRequest, redirectURI: URL) async -> URLRequest? {
    
        await performRequestHandler(request, redirectURI)
    }
    
    public func finish(with error: Error?) async {
        
        await finishHandler?(error)
    }
}

extension UserAgent where Self == AnyUserAgent {
    
    public static func any(performRequestHandler: @escaping Self.PerformRequestHandler, finishHandler: Self.FinishHandler? = nil) -> Self {
        
        .init(
            performRequestHandler: performRequestHandler,
            finishHandler: finishHandler
        )
    }
}
