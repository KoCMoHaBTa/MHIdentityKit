//
//  DefaultAccessTokenRefresher.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 6/2/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

open class DefaultAccessTokenRefresher: AccessTokenRefresher {
    
    public let tokenEndpoint: URL
    public let networkClient: NetworkClient
    public let clientAuthorizer: RequestAuthorizer
    
    public init(tokenEndpoint: URL, networkClient: NetworkClient = .default, clientAuthorizer: RequestAuthorizer) {
        
        self.tokenEndpoint = tokenEndpoint
        self.networkClient = networkClient
        self.clientAuthorizer = clientAuthorizer
    }
    
    open func refresh(using requestModel: AccessTokenRefreshRequest) async throws -> AccessTokenResponse {
        
        var request = URLRequest(url: tokenEndpoint)
        request.httpMethod = "POST"
        request.httpBody = requestModel.dictionary.urlEncodedParametersData
        try await request.authorize(using: clientAuthorizer)
        let networkResponse = try await networkClient.perform(request)
        let accessTokenResponse = try AccessTokenResponse(from: networkResponse)
        return accessTokenResponse
    }
}

extension DefaultAccessTokenRefresher {
    
    public convenience init(tokenEndpoint: URL, clientID: String, secret: String) {
        
        self.init(tokenEndpoint: tokenEndpoint, clientAuthorizer: HTTPBasicAuthorizer(clientID: clientID, secret: secret))
    }
}

extension AccessTokenRefresher where Self == DefaultAccessTokenRefresher {
    
    public static func `default`(tokenEndpoint: URL, networkClient: NetworkClient = .default, clientAuthorizer: RequestAuthorizer) -> Self {
        
        .init(tokenEndpoint: tokenEndpoint, networkClient: networkClient, clientAuthorizer: clientAuthorizer)
    }
    
    public static func `default`(tokenEndpoint: URL, clientID: String, secret: String) -> Self {
        
        .init(tokenEndpoint: tokenEndpoint, clientAuthorizer: HTTPBasicAuthorizer(clientID: clientID, secret: secret))
    }
}
