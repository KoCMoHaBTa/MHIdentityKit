//
//  ResourceOwnerPasswordCredentialsGrantFlow.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 4/12/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

//https://tools.ietf.org/html/rfc6749#section-1.3.3
//https://tools.ietf.org/html/rfc6749#section-4.3
public class ResourceOwnerPasswordCredentialsGrantFlow: AuthorizationGrantFlow {
    
    public let tokenEndpoint: URL
    public let clientID: String
    public let secret: String
    public let credentialsProvider: CredentialsProvider
    public let scope: Scope?
    public let networkClient: NetworkClient
    public let storage: IdentityStorage
    
    public private(set) var accessTokenResponse: AccessTokenResponse? {
        
        didSet {
            
            self.refreshToken = self.accessTokenResponse?.refreshToken
        }
    }
    
    private static let refreshTokenKey = Bundle(for: ResourceOwnerPasswordCredentialsGrantFlow.self).bundleIdentifier! + ".refreshToken"
    private var refreshToken: String? {
        
        get {
            
            return self.storage.value(forKey: type(of: self).refreshTokenKey)
        }
        
        set {
            
            self.storage.set(newValue, forKey: type(of: self).refreshTokenKey)
        }
    }
    
    private var canRefreshAccessToken: Bool {
        
        return self.refreshToken != nil
    }
    
    //MARK: - Init
    
    public init(tokenEndpoint: URL, clientID: String, secret: String, credentialsProvider: CredentialsProvider, scope: Scope? = nil, networkClient: NetworkClient = DefaultNetoworkClient(), storage: IdentityStorage) {
        
        self.tokenEndpoint = tokenEndpoint
        self.clientID = clientID
        self.secret = secret
        self.credentialsProvider = credentialsProvider
        self.scope = scope
        
        self.networkClient = networkClient
        self.storage = storage
    }
    
    public convenience init(tokenEndpoint: URL, clientID: String, secret: String, username: String, password: String, scope: Scope? = nil, storage: IdentityStorage) {
        
        self.init(tokenEndpoint: tokenEndpoint, clientID: clientID, secret: secret, credentialsProvider: DefaultCredentialsProvider(username: username, password: password), scope: scope, storage: storage)
    }
    
    //MARK: - AuthorizationGrantFlow
    
    public func authenticate(handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
        
        //try to refresh the access token first
        if self.canRefreshAccessToken {
            
            self.refreshAccessToken(handler: { (response, error) in
                
                self.accessTokenResponse = response
                
                if response == nil {
                    
                    self.authenticate(handler: handler)
                }
                else {
                    
                    handler(response, error)
                }
            })
        }
        else {
            
            self.requestAccessToken(handler: { (response, error) in
                
                self.accessTokenResponse = response
                handler(response, error)
            })
        }
    }
    
    public func authorize(request: URLRequest, handler: @escaping (URLRequest, Error?) -> Void) {
        
        do {
            
            //check if we have access token
            guard let accessTokenResponse = self.accessTokenResponse else {
                
                throw MHIdentityKitError.authorizationFailed(reason: .clientNotAuthenticated)
            }
            
            //check if the access token has expired
            guard accessTokenResponse.isExpired == false else {
                
                throw MHIdentityKitError.authorizationFailed(reason: .tokenExpired)
            }
            
            var request = request
            let authorizationHeader = self.buildAuthorizationHeader(from: accessTokenResponse)
            request.setValue(authorizationHeader, forHTTPHeaderField: "Authorization")
        }
        catch {
            
            handler(request, error)
        }
    }
    
    //MARK: - Authorization
    
    private func requestAccessToken(handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
        
        self.credentialsProvider.credentials { [unowned self] (username, password) in
            
            //build the request
            var request = URLRequest(url: self.tokenEndpoint)
            request.httpMethod = "POST"
            request.httpBody = AccessTokenRequest(username: username, password: password, scope: self.scope).dictionary.urlEncodedParametersData
            
            do {
                
                //try to build the authentication header
                let authenticationHeader = try self.buildAuthenticationHeader(clientID: self.clientID, secret: self.secret)
                request.setValue(authenticationHeader, forHTTPHeaderField: "Authorization")
            }
            catch {
                
                DispatchQueue.main.async {
                    
                    handler(nil, error)
                }
                
                return
            }
            
            //perform the request
            self.networkClient.perform(request: request, handler: { (data, response, error) in
                
                do {
                    
                    //if there is an error - throw it
                    if let error = error {
                        
                        throw error
                    }
                    
                    //if response is unknown - throw an error
                    guard let response = response as? HTTPURLResponse else {
                        
                        throw MHIdentityKitError.authenticationFailed(reason: .unknownURLResponse)
                    }
                    
                    //parse the data
                    guard
                    let data = data,
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    else {
                        
                        throw MHIdentityKitError.authenticationFailed(reason: .unableToParseAccessToken)
                    }
                    
                    //if the error is one of the defined in the OAuth2 framework - throw it
                    if let error = ErrorResponse(json: json) {
                        
                        throw error
                    }
                    
                    //make sure the response code is success 2xx
                    guard (200..<300).contains(response.statusCode) else {
                        
                        throw MHIdentityKitError.authenticationFailed(reason: .unknownHTTPResponse(code: response.statusCode))
                    }
                    
                    //parse the access token
                    let accessTokenResponse = AccessTokenResponse(json: json)
                    
                    DispatchQueue.main.async {
                        
                        handler(accessTokenResponse, nil)
                    }
                }
                catch {
                    
                    DispatchQueue.main.async {
                        
                        handler(nil, error)
                    }
                }
            })
        }
    }
    
    private func refreshAccessToken(handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
        
        
    }
    
    ///Build the header needed to authorize a request
    private func buildAuthorizationHeader(from response: AccessTokenResponse) -> String {
        
        //eg. "Bearer xyz123asd"
        let header = response.tokenType + " " + response.accessToken
        return header
    }
    
    //MARK: - Authentication
    
    ///Build the header needed to sign the authentication request
    private func buildAuthenticationHeader(clientID: String, secret: String) throws -> String {
        
        guard let client = (clientID + ":" + secret).data(using: .utf8)?.base64EncodedString() else {
            
            throw MHIdentityKitError.authenticationFailed(reason: .buildAuthenticationHeaderFailed)
        }
        
        let header = "Basic " + client
        return header
    }
}

//MARK: - Models

extension ResourceOwnerPasswordCredentialsGrantFlow {
    
    //https://tools.ietf.org/html/rfc6749#section-4.3.2
    fileprivate struct AccessTokenRequest {
        
        let grantType: GrantType = .password
        let username: String
        let password: String
        let scope: Scope?
        
        var dictionary: [String: Any] {
            
            var dictionary = [String: Any]()
            dictionary["grant_type"] = self.grantType.rawValue
            dictionary["username"] = self.username
            dictionary["password"] = self.password
            dictionary["scope"] = self.scope?.value
            
            return dictionary
        }
    }
    
    
}
