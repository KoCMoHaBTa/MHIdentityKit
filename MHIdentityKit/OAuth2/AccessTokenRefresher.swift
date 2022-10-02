//
//  AccessTokenRefresher.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 5/24/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///A type that refresh an access token using a refresh token
public protocol AccessTokenRefresher {
    
    func refresh(using requestModel: AccessTokenRefreshRequest, handler: @escaping (AccessTokenResponse?, Error?) -> Void)
}

extension AccessTokenRefresher {
    
    @available(iOS 13, tvOS 13, macOS 10.15, watchOS 6, *)
    public func refresh(using requestModel: AccessTokenRefreshRequest) async throws -> AccessTokenResponse {
        
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
