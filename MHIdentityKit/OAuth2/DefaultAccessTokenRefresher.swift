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
    
    public init(tokenEndpoint: URL, networkClient: NetworkClient = _defaultNetworkClient, clientAuthorizer: RequestAuthorizer) {
        
        self.tokenEndpoint = tokenEndpoint
        self.networkClient = networkClient
        self.clientAuthorizer = clientAuthorizer
    }
    
    open func refresh(using requestModel: AccessTokenRefreshRequest, handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
        
        var request = URLRequest(url: self.tokenEndpoint)
        request.httpMethod = "POST"
        request.httpBody = requestModel.dictionary.urlEncodedParametersData
        
        request.authorize(using: self.clientAuthorizer) { (request, error) in
            
            guard error == nil else {
                
                handler(nil, error)
                return
            }
            
            self.networkClient.perform(request) { (response) in
                
                do {
                    
                    let accessTokenResponse = try AccessTokenResponseHandler().handle(response: response)
                    
                    DispatchQueue.main.async {
                        
                        handler(accessTokenResponse, nil)
                    }
                }
                catch let error as LocalizedError {
                    
                    DispatchQueue.main.async {
                        
                        handler(nil, MHIdentityKitError.authenticationFailed(reason: error))
                    }
                }
                catch {
                    
                    DispatchQueue.main.async {
                        
                        handler(nil, MHIdentityKitError.authenticationFailed(reason: MHIdentityKitError(error: error)))
                    }
                }
            }
        }
    }
    
    @available(iOS 13, tvOS 13.0.0, macOS 10.15, *)
    open func refresh(using requestModel: AccessTokenRefreshRequest) async throws -> AccessTokenResponse {
        
        return try await withCheckedThrowingContinuation { continuation in
            
            self.refresh(using: requestModel) { response, error in
                
                if let error = error {
                    continuation.resume(throwing: error)
                }
                else {
                    
                    guard let response = response else {
                        continuation.resume(throwing: MHIdentityKitError.Reason.invalidAccessTokenResponse)
                        return
                    }
                    
                    continuation.resume(returning: response)
                }
            }
        }
    }
}

extension DefaultAccessTokenRefresher {
    
    public convenience init(tokenEndpoint: URL, clientID: String, secret: String) {
        
        self.init(tokenEndpoint: tokenEndpoint, clientAuthorizer: HTTPBasicAuthorizer(clientID: clientID, secret: secret))
    }
}
