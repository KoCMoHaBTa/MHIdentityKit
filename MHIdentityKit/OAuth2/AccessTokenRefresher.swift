//
//  AccessTokenRefresher.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/24/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

//https://tools.ietf.org/html/rfc6749#section-6
public class AccessTokenRefresher {
    
    public let tokenEndpoint: URL
    public let networkClient: NetworkClient
    public let clientAuthorizer: RequestAuthorizer
    
    public init(tokenEndpoint: URL, networkClient: NetworkClient, clientAuthorizer: RequestAuthorizer) {
        
        self.tokenEndpoint = tokenEndpoint
        self.networkClient = networkClient
        self.clientAuthorizer = clientAuthorizer
    }
    
    public func refresh(using requestModel: Request, handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
        
        var request = URLRequest(url: self.tokenEndpoint)
        request.httpMethod = "POST"
        request.httpBody = requestModel.dictionary.urlEncodedParametersData
        
        request.authorize(using: self.clientAuthorizer) { (request, error) in
            
            guard error == nil else {
                
                handler(nil, error)
                return
            }
            
            self.networkClient.perform(request: request) { (data, response, error) in
                
                do {
                    
                    let accessTokenResponse = try AccessTokenResponseHandler().handle(data: data, response: response, error: error)
                    
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

extension AccessTokenRefresher {
    
    public struct Request {
        
        public let grantType: GrantType = .refreshToken
        public let refreshToken: String
        public let scope: Scope?
        
        var dictionary: [String: Any] {
            
            var dictionary = [String: Any]()
            dictionary["grant_type"] = self.grantType.rawValue
            dictionary["refresh_token"] = self.refreshToken
            dictionary["scope"] = self.scope?.value
            
            return dictionary
        }
    }
}
