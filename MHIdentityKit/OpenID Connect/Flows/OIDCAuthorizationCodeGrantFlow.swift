//
//  OIDCAuthorizationCodeGrantFlow.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 10.07.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation

///[CodeFlowAuth](https://openid.net/specs/openid-connect-core-1_0.html#CodeFlowAuth)
open class OIDCAuthorizationCodeGrantFlow: AuthorizationCodeGrantFlow {

    ///The Issuer Identifier for the OpenID Provider (which is typically obtained during Discovery).
    ///For more information, see [ProviderMetadata](https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderMetadata)
    public let issuer: URL
    
    ///It is not clear what the possible values of this parameter is.
    open var responseMode: Any?
    
    ///[NonceNotes](https://openid.net/specs/openid-connect-core-1_0.html#NonceNotes)
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
    
    ///List of any trusted audiences, based on which the ID token should be validated. Default to `nil`, which do not perform validation for trusted audiences.
    open var trustedAudiences: [String]?
    
    /**
     Creates an instance of the receiver.
     
     - parameter issuer: The Issuer Identifier for the OpenID Provider (which is typically obtained during Discovery). For more information, see [ProviderMetadata](https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderMetadata)
     - parameter authorizationEndpoint: The URL of the authorization endpoint
     - parameter tokenEndpoint: The URL of the token endpoint
     - parameter clientID: The client identifier as described in [Section 2.2](https://tools.ietf.org/html/rfc6749#section-2.2)
     - parameter redirectURI: As described in [Section 3.1.2](https://tools.ietf.org/html/rfc6749#section-3.1.2)
     - parameter scope: The scope of the access request as described by [Section 3.3](https://tools.ietf.org/html/rfc6749#section-3.3)
     - parameter state: An opaque value used by the client to maintain state between the request and callback. The authorization server includes this value when redirecting the user-agent back to the client. The parameter SHOULD be used for preventing cross-site request forgery as described in [Section 10.12](https://tools.ietf.org/html/rfc6749#section-10.12)
     - parameter clientAuthorizer: An optional authorizer used to authorize the authentication request.
     - parameter userAgent: The user agent used to perform the authroization request and handle redirects.
     - parameter networkClient: A network client used to perform the authentication request.
     
     */
    
    public init(issuer: URL, authorizationEndpoint: URL, tokenEndpoint: URL, clientID: String, redirectURI: URL?, scope: Scope?, state: AnyHashable? = NSUUID().uuidString, clientAuthorizer: RequestAuthorizer?, userAgent: UserAgent, networkClient: NetworkClient = _defaultNetworkClient) {
        
        self.issuer = issuer
        super.init(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
    }
    
    /**
     Creates an instance of the receiver.
     
     - parameter issuer: The Issuer Identifier for the OpenID Provider (which is typically obtained during Discovery). For more information, see [ProviderMetadata](https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderMetadata)
     - parameter authorizationEndpoint: The URL of the authorization endpoint
     - parameter tokenEndpoint: The URL of the token endpoint
     - parameter clientID: The client identifier as described in [Section 2.2](https://tools.ietf.org/html/rfc6749#section-2.2)
     - parameter secret: The secret, used to authorize confidential clients as described in [Section 4.1.3](https://tools.ietf.org/html/rfc6749#section-4.1.3) and [Section 3.2.1](https://tools.ietf.org/html/rfc6749#section-3.2.1)
     - parameter redirectURI: As described in [Section 3.1.2](https://tools.ietf.org/html/rfc6749#section-3.1.2)
     - parameter scope: The scope of the access request as described by [Section 3.3](https://tools.ietf.org/html/rfc6749#section-3.3)
     - parameter userAgent: The user agent used to perform the authroization request and handle redirects.
     - parameter networkClient: A network client used to perform the authentication request.
     
     */
    
    public convenience init(issuer: URL, authorizationEndpoint: URL, tokenEndpoint: URL, clientID: String, secret: String?, redirectURI: URL?, scope: Scope?, state: AnyHashable? = NSUUID().uuidString, userAgent: UserAgent, networkClient: NetworkClient = _defaultNetworkClient) {
        
        var clientAuthorizer: RequestAuthorizer?
        if let secret = secret {
            
            clientAuthorizer = HTTPBasicAuthorizer(clientID: clientID, secret: secret)
        }
        
        self.init(issuer: issuer, authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, clientID: clientID, redirectURI: redirectURI, scope: scope, state: state, clientAuthorizer: clientAuthorizer, userAgent: userAgent, networkClient: networkClient)
    }
    
//    open var jwsSignatureVerifier: JWSSignatureVerifier = RS256SignatureVerifier(

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
        
        //https://openid.net/specs/openid-connect-core-1_0.html#CodeIDToken
        fatalError("validate id token hash, if present")
        //Access Token hash value. Its value is the base64url encoding of the left-most half of the hash of the octets of the ASCII representation of the access_token value, where the hash algorithm used is the hash algorithm used in the alg Header Parameter of the ID Token's JOSE Header.
        //For instance, if the alg is RS256, hash the access_token value with SHA-256, then take the left-most 128 bits and base64url encode them. The at_hash value is a case sensitive string.
        
        //https://openid.net/specs/openid-connect-core-1_0.html#IDTokenValidation
        //1. If the ID Token is encrypted, decrypt it using the keys and algorithms that the Client specified during Registration that the OP was to use to encrypt the ID Token. If encryption was negotiated with the OP at Registration time and the ID Token is not encrypted, the RP SHOULD reject it.
        //NOTE: The library does not yet support encrypted tokens (JWE)
        
        //2. The Issuer Identifier for the OpenID Provider (which is typically obtained during Discovery) MUST exactly match the value of the iss (issuer) Claim.
        guard idToken.iss == self.issuer else {
            
            throw MHIdentityKitError.authenticationFailed(reason: MHIdentityKitError.Reason.invalidIDToken(reason: .invalidIssuer))
        }
        
        //3. The Client MUST validate that the aud (audience) Claim contains its client_id value registered at the Issuer identified by the iss (issuer) Claim as an audience. The aud (audience) Claim MAY contain an array with more than one element. The ID Token MUST be rejected if the ID Token does not list the Client as a valid audience, or if it contains additional audiences not trusted by the Client.
        
        guard idToken.aud.contains(clientID: self.clientID)
           && idToken.aud.validate(trusted: IDToken.Audience(self.trustedAudiences))
        else {
            
            throw MHIdentityKitError.authenticationFailed(reason: MHIdentityKitError.Reason.invalidIDToken(reason: .invalidAudience))
        }
        
        //4. If the ID Token contains multiple audiences, the Client SHOULD verify that an azp Claim is present.
        if case .array = idToken.aud {
            
            guard idToken.azp != nil else {
                
                throw MHIdentityKitError.authenticationFailed(reason: MHIdentityKitError.Reason.invalidIDToken(reason: .invalidAuthorizedParty))
            }
        }
        
        //5. If an azp (authorized party) Claim is present, the Client SHOULD verify that its client_id is the Claim Value.
        if let azp = idToken.azp {
            
            guard azp == self.clientID else {
                
                throw MHIdentityKitError.authenticationFailed(reason: MHIdentityKitError.Reason.invalidIDToken(reason: .invalidAuthorizedParty))
            }
        }
        
        //6. If the ID Token is received via direct communication between the Client and the Token Endpoint (which it is in this flow), the TLS server validation MAY be used to validate the issuer in place of checking the token signature. The Client MUST validate the signature of all other ID Tokens according to JWS [JWS] using the algorithm specified in the JWT alg Header Parameter. The Client MUST use the keys provided by the Issuer.
        fatalError("Verify token signature")
//        idToken.jwt.verify(using: <#T##SignatureVerifier#>) -> should be simple as this
//        try self.jwsSignatureVerifier.verify(token: idToken.jwt) -> can't remember the purpose of this one
        //NOTE: Think of a way to automatically detect proper signature verifier with the ability for clients to define and provide their own
        
        //7. The alg value SHOULD be the default of RS256 or the algorithm sent by the Client in the id_token_signed_response_alg parameter during Registration.
        //Details in https://openid.net/specs/openid-connect-registration-1_0.html
        //NOTE: It might turns out that a given client can have single type of alg at any given time, expect when explicitly changed.
        //QUESTION: Should we support dynamic alg changes or we should rely on explciit single one? It would be nice to adapt dynamically.
        fatalError("Verfy alg")
        
        //8.
        //9.
        //10.
        //11.
        //12.
        //13.
        
        //https://openid.net/specs/openid-connect-core-1_0.html#CodeFlowTokenValidation
        fatalError("validate access token")
    }
}

