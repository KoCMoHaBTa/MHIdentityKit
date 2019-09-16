//
//  OIDCAuthorizationCodeGrantFlow.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 10.07.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation

//https://openid.net/specs/openid-connect-core-1_0.html#CodeFlowAuth
open class OIDCAuthorizationCodeGrantFlow: AuthorizationCodeGrantFlow {
    
    ///It is not clear what the possible values of this parameter is.
    open var responseMode: Any?
    
    ///https://openid.net/specs/openid-connect-core-1_0.html#NonceNotes
    open var nounce: String?
    
    ///Specifies how the Authorization Server displays the authentication and consent user interface pages to the End-User. For more information and possible values, see the 'display' parameter in the [Authorization Request](https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest)
    open var display: String?
    
    ///Space delimited, case sensitive list of ASCII string values that specifies whether the Authorization Server prompts the End-User for reauthentication and consent. For more information and possible values, see the 'prompt' parameter in the [Authorization Request](https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest)
    open var prompt: String?
    
    ///Maximum Authentication Age. For more information and possible values, see the 'max_age' parameter in the [Authorization Request](https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest)
    open var maxAge: String?
    
    ///End-User's preferred languages and scripts for the user interface. For more information and possible values, see the 'ui_locales' parameter in the [Authorization Request](https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest)
    open var uiLocales: String?
    
    /// ID Token previously issued by the Authorization Server being passed as a hint about the End-User's current or past authenticated session with the Client. For more information and possible values, see the 'id_token_hint' parameter in the [Authorization Request](https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest)
    open var idTokenHint: String?
    
    ///Hint to the Authorization Server about the login identifier the End-User might use to log in. For more information and possible values, see the 'login_hint' parameter in the [Authorization Request](https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest)
    open var loginHint: String?
    
    ///Requested Authentication Context Class Reference values. For more information and possible values, see the 'acr_values' parameter in the [Authorization Request](https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest)
    open var acrValues: String?
    
    ///If using the HTTP GET method, the request parameters are serialized using URI Query String Serialization, per [Section 13.1](https://openid.net/specs/openid-connect-core-1_0.html#QuerySerialization). If using the HTTP POST method, the request parameters are serialized using Form Serialization, per [Section 13.2](https://openid.net/specs/openid-connect-core-1_0.html#FormSerialization). Default to 'GET'.
    open var authorizationRequestHTTPMethod: String = "GET"
    
    open var jwsSignatureVerifier: JWSSignatureVerifier = JWSSignatureVerifierRegistry.default

    //MARK: - Flow logic
    
    //https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest
    open override func authorizationRequestParameters() -> [String : Any] {
        
        var parameters = super.authorizationRequestParameters()
        
        //scope is requried and must contain 'openid'
        parameters["scope"] = self.scope?.addingOpenIDScopeIfNeeded() ?? .openid
        parameters["response_mode"] = self.responseMode
        parameters["nounce"] = self.nounce
        parameters["display"] = self.display
        parameters["prompt"] = self.prompt
        parameters["max_age"] = self.maxAge
        parameters["ui_locales"] = self.uiLocales
        parameters["id_token_hint"] = self.idTokenHint
        parameters["login_hint"] = self.loginHint
        parameters["acr_values"] = self.acrValues
        
        return parameters
    }
    
    open override func authorizationRequest(withParameters parameters: [String : Any]) -> URLRequest {
        
        //add support for 'POST' request
        if self.authorizationRequestHTTPMethod == "POST" {
            
            let url = self.authorizationEndpoint
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = parameters.urlEncodedParametersData
            
            return request
        }
        else {
            
            return super.authorizationRequest(withParameters: parameters)
        }
    }
    
    open override func validate(accessTokenResponse: AccessTokenResponse) throws {
        
        //https://openid.net/specs/openid-connect-core-1_0.html#TokenResponse
        guard let idToken = accessTokenResponse.idToken else {
            
            throw MHIdentityKitError.authenticationFailed(reason: MHIdentityKitError.Reason.invalidAccessTokenResponse)
        }
        
        try self.jwsSignatureVerifier.verify(token: idToken.jwt)
        
        //https://openid.net/specs/openid-connect-core-1_0.html#CodeIDToken
//        fatalError("validate id token hash, if present")
        
        //https://openid.net/specs/openid-connect-core-1_0.html#IDTokenValidation
        fatalError("validate id token")
        //iss 
        //https://openid.net/specs/openid-connect-core-1_0.html#CodeFlowTokenValidation
        fatalError("validate access token")
    }
}

