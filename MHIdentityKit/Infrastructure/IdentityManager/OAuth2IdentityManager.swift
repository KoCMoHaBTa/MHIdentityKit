//
//  OAuth2IdentityManager.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 6/5/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///Perform an authorization using an OAuth2 AuthorizationGrantFlow for authentication with a behaviour that refresh a token if possible and preserves a state.
///The core logic is ilustrated here - https://tools.ietf.org/html/rfc6749#section-1.5
open actor OAuth2IdentityManager: IdentityManager {
    
    //used for authentication - getting OAuth2 access token
    public let flow: AuthorizationGrantFlow
    
    //used to refresh an access token using a refresh token if aplicable
    public let refresher: AccessTokenRefresher?
    
    //used to store state, like the refresh token
    public let storage: IdentityStorage?
    
    //used to provide an authorizer that authorize the request using the provided access token response
    public let tokenAuthorizerProvider: (AccessTokenResponse) -> RequestAuthorizer
    
    /**
     Creates an instnce of the receiver.
     
     - parameter flow: An OAuth2 authorization grant flow used for authentication.
     - parameter refresher: An optional access token refresher, used to refresh an access token if expired and when possible.
     - parameter storage: An identity storage, used to store some state, like the refresh token.
     - parameter tokenAuthorizerProvider: A closure that provides a request authorizer used to authorize incoming requests with the provided access token
     
     */
    
    public init(flow: AuthorizationGrantFlow, refresher: AccessTokenRefresher?, storage: IdentityStorage?, tokenAuthorizerProvider: @escaping (AccessTokenResponse) -> RequestAuthorizer) {
        
        self.flow = flow
        self.refresher = refresher
        self.storage = storage
        self.tokenAuthorizerProvider = tokenAuthorizerProvider
    }
    
    //MARK: - Configuration
    
    public struct Configuration {
        
        ///Controls whenver an authentication should be forced if a refresh fails. If `true`, when a refresh token fails, an authentication will be performed automatically using the flow provided. If `false` an error will be returned. Default to `true`.
        public var forceAuthenticateOnRefreshError = true
        
        /***
         Controls whenever an authorization should be retried if an authentication fails. If `true`, when an authentication fails - the authorization will be retried automatically untill there is a successfull authentication. If `false` an error will be returned. Default to `false`.
         
         - note: This behaviour is needed when the authorization requires user input, like in the `ResourceOwnerPasswordCredentialsGrantFlow` where the `CredentialsProvider` is a login screen. As opposite it is not needed when user input is not involved, because it could lead to infinite loop of authorizations.
         
         */
        
        public var retryAuthorizationOnAuthenticationError = false
        
        public init() {}
    }
    
    open var configuration: Configuration = .init()
    
    ///Updates the recevier's configuration
    open func configure(_ configurator: (_ configuration: inout Configuration) -> Void) {
        
        configurator(&configuration)
    }
    
    //MARK: - State
    
    private var accessTokenResponse: AccessTokenResponse? {
        
        didSet {
            
            self.storage?.refreshToken = self.accessTokenResponse?.refreshToken
            self.storage?.scope = self.accessTokenResponse?.scope
        }
    }
    
    ///The available refresh token - either from the access token response or from the storage.
    var refreshToken: String? {
        
        let refreshToken = self.accessTokenResponse?.refreshToken ?? self.storage?.refreshToken
        
        //if token is empty string - ignore it
        if refreshToken?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            
            return nil
        }
        
        return refreshToken
    }
    
    private var scope: Scope? {
        
        let scope = self.accessTokenResponse?.scope ?? self.storage?.scope
        return scope
    }
    
    //MARK: - IdentityManager
    
    private func performAuthentication() async throws-> AccessTokenResponse {
        
        postWillAuthenticateNotification()
        
        do {
            
            let respone = try await flow.authenticate()
            didFinishAuthenticating(with: respone)
            return respone
        }
        catch {
            
            didFailAuthenticating(with: error)
            throw error
        }
    }
    
    //make the authentication serial
    private var authenticateTaskHandle: Any? = nil
    private func authenticate(forced: Bool) async throws -> AccessTokenResponse {

        if #available(iOS 15.0, *) {

            if let authenticateTaskHandle = authenticateTaskHandle as? Task.Handle<AccessTokenResponse, Error> {

                return try await authenticateTaskHandle.get()
            }

            let authenticateTaskHandle = async {

                try await _authenticate(forced: forced)
            }

            self.authenticateTaskHandle = authenticateTaskHandle

            let response = try await authenticateTaskHandle.get()
            self.authenticateTaskHandle = nil
            return response
        }
        else { fatalError("Xcode 13 Beta 1 requires iOS 15 for all async/await APIs ") }
    }
    
    private func _authenticate(forced: Bool) async throws -> AccessTokenResponse {
                
        //force authenticate
        if forced {
            
            //authenticate
            return try await performAuthentication()
        }
        
        //refresh if possible
        if let refresher = refresher, let refreshToken = refreshToken {
            
            do {
                let request = AccessTokenRefreshRequest(refreshToken: refreshToken, scope: scope)
                return try await refresher.refresh(using: request)
            }
            catch {
                
                if let error = error as? MHIdentityKitError, error.contains(error: OAuth2Error.self) {
                
                    //if the error returned is ErrorResponse - clear the existing refresh token
                    accessTokenResponse?.refreshToken = nil
                    
                    //if force authentication is enabled upon refresh error, and the error returned is ErrorResponse - perform a new authentication
                    if configuration.forceAuthenticateOnRefreshError == true {
                        
                        //authenticate
                        return try await performAuthentication()
                    }
                }
                
                throw error
            }
        }
        
        //authenticate
        return try await performAuthentication()
    }
    
    private func performAuthorization(request: URLRequest, forceAuthenticate: Bool) async throws -> URLRequest {
        
        if forceAuthenticate == false, let response = accessTokenResponse, response.isExpired == false   {
            
            return try await tokenAuthorizerProvider(response).authorize(request: request)
        }
        
        do {
            let response = try await authenticate(forced: forceAuthenticate)
            accessTokenResponse = response
            return try await tokenAuthorizerProvider(response).authorize(request: request)
        }
        catch {
            
            if configuration.retryAuthorizationOnAuthenticationError == true && error is OAuth2Error {
                
                return try await performAuthorization(request: request, forceAuthenticate: forceAuthenticate)
            }
            
            throw error
        }
    }
    
    //MARK: - IdentityManager
    
    open func authorize(request: URLRequest, forceAuthenticate: Bool) async throws -> URLRequest {
        
        try await performAuthorization(request: request, forceAuthenticate: forceAuthenticate)
    }
    
    open func revokeAuthenticationState() async {
        
        accessTokenResponse = nil
            
        //TODO: implement token revocation trough server
    }
    
    open func revokeAuthorizationState() async {
        
        accessTokenResponse?.expiresIn = 0
    }
    
    open var responseValidator: NetworkResponseValidator = {

        struct PlaceholderIdentityManager: IdentityManager {

            func authorize(request: URLRequest, forceAuthenticate: Bool) async throws -> URLRequest { request }
            func revokeAuthenticationState() async {}
            func revokeAuthorizationState() async {}

            static let defaultResponseValidator = PlaceholderIdentityManager().responseValidator
        }

        return PlaceholderIdentityManager.defaultResponseValidator
    }()
}

extension OAuth2IdentityManager {
    
    /**
     Creates an instnce of the receiver when the access token is expected to be of a Bearer type with a specified authorization method.
     
     - parameter flow: An OAuth2 authorization grant flow used for authentication.
     - parameter refresher: An optional access token refresher, used to refresh an access token if expired and when possible.
     - parameter storage: An identity storage, used to store some state, like the refresh token.
     - parameter authorizationMethod: The authorization method used to authorize the requests. Default to `.header`
     
     */
    
    public convenience init(flow: AuthorizationGrantFlow, refresher: AccessTokenRefresher?, storage: IdentityStorage?, authorizationMethod: BearerAccessTokenAuthorizer.AuthorizationMethod = .header) {
        
        let tokenAuthorizerProvider = { (response: AccessTokenResponse) -> RequestAuthorizer in
            
            return BearerAccessTokenAuthorizer(token: response.accessToken, method: authorizationMethod)
        }
        
        self.init(flow: flow, refresher: refresher, storage: storage, tokenAuthorizerProvider: tokenAuthorizerProvider)
    }
}

extension OAuth2IdentityManager {
    
    public static let willAuthenticate = Notification.Name(rawValue: bundleIdentifier + ".OAuth2IdentityManager.willAuthenticate")
    public static let didAuthenticate = Notification.Name(rawValue: bundleIdentifier + ".OAuth2IdentityManager.didAuthenticate")
    public static let didFailToAuthenticate = Notification.Name(rawValue: bundleIdentifier + ".OAuth2IdentityManager.didFailToAuthenticate")
    
    public static let accessTokenResponseUserInfoKey = "accessTokenResponse"
    public static let errorUserInfoKey = "error"
    
    ///notify that authentication will begin
    private func postWillAuthenticateNotification() {
        
        let notification = Notification(name: type(of: self).willAuthenticate, object: self, userInfo: nil)
        NotificationQueue.default.enqueue(notification, postingStyle: .now)
    }
    
    ///notify that authentication has finished
    private func didFinishAuthenticating(with accessTokenResponse: AccessTokenResponse) {
        
        var userInfo = [AnyHashable: Any]()
        userInfo[Self.accessTokenResponseUserInfoKey] = accessTokenResponse
        
        let notification = Notification(name: Self.didAuthenticate, object: self, userInfo: userInfo)
        NotificationQueue.default.enqueue(notification, postingStyle: .now)
    }
    
    private func didFailAuthenticating(with error: Error) {
        
        var userInfo = [AnyHashable: Any]()
        userInfo[Self.errorUserInfoKey] = error
        
        let notification = Notification(name: Self.didFailToAuthenticate, object: self, userInfo: userInfo)
        NotificationQueue.default.enqueue(notification, postingStyle: .now)
    }
}

extension Notification.Name {
    
    public static let OAuth2IdentityManagerWillAuthenticate = OAuth2IdentityManager.willAuthenticate
    public static let OAuth2IdentityManagerDidAuthenticate = OAuth2IdentityManager.didAuthenticate
    public static let OAuth2IdentityManagerDidFailToAuthenticate = OAuth2IdentityManager.didFailToAuthenticate
}

extension IdentityStorage {
    
    private var refreshTokenKey: String {
        
        return bundleIdentifier + ".OAuth2IdentityManager.refresh_token"
    }
    
    fileprivate var refreshToken: String? {
        
        get { self[refreshTokenKey] }
        set { self[refreshTokenKey] = newValue }
    }
}

extension IdentityStorage {
    
    private var scopeValueKey: String {
        
        return bundleIdentifier + ".OAuth2IdentityManager.scope_value"
    }
    
    fileprivate var scope: Scope? {
        
        get { self[scopeValueKey].map { .init(rawValue: $0) } }
        set { self[scopeValueKey] = newValue?.rawValue }
    }
}
