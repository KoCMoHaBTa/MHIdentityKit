//
//  DefaultAccessTokenRefresher.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 6/2/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

public class DefaultAccessTokenRefresher: AccessTokenRefresher {
    
    public let tokenEndpoint: URL
    public let networkClient: NetworkClient
    public let clientAuthorizer: RequestAuthorizer
    
    public init(tokenEndpoint: URL, networkClient: NetworkClient, clientAuthorizer: RequestAuthorizer) {
        
        self.tokenEndpoint = tokenEndpoint
        self.networkClient = networkClient
        self.clientAuthorizer = clientAuthorizer
    }
    
    public func refresh(using requestModel: AccessTokenRefreshRequest, handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
        
        var request = URLRequest(url: self.tokenEndpoint)
        request.httpMethod = "POST"
        request.httpBody = requestModel.dictionary.urlEncodedParametersData
        
        request.authorize(using: self.clientAuthorizer) { (request, error) in
            
            guard error == nil else {
                
                handler(nil, error)
                return
            }
            
            self.networkClient.perform(request: request) { (response) in
                
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
}

extension DefaultAccessTokenRefresher {
    
    public convenience init(tokenEndpoint: URL, clientID: String, secret: String) {
        
        self.init(tokenEndpoint: tokenEndpoint, networkClient: DefaultNetoworkClient(), clientAuthorizer: HTTPBasicAuthorizer(clientID: clientID, secret: secret))
    }
}
