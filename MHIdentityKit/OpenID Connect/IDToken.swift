//
//  IDToken.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 15.07.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation

//https://openid.net/specs/openid-connect-core-1_0.html#IDToken
public struct IDToken {
    
    /// Issuer Identifier for the Issuer of the response. The iss value is a case sensitive URL using the https scheme that contains scheme, host, and optionally, port number and path components and no query or fragment components.
    public let iss: URL
    
    ///Subject Identifier. A locally unique and never reassigned identifier within the Issuer for the End-User, which is intended to be consumed by the Client, e.g., 24400320 or AItOawmwtWwcT0k51BayewNvutrJUqsvl6qs7A4. It MUST NOT exceed 255 ASCII characters in length. The sub value is a case sensitive string.
    public let sub: String
    
    ///Audience(s) that this ID Token is intended for. It MUST contain the OAuth 2.0 client_id of the Relying Party as an audience value. It MAY also contain identifiers for other audiences. In the general case, the aud value is an array of case sensitive strings. In the common special case when there is one audience, the aud value MAY be a single case sensitive string.
    public let aud: String
    
    ///Expiration time on or after which the ID Token MUST NOT be accepted for processing. The processing of this parameter requires that the current date/time MUST be before the expiration date/time listed in the value. Implementers MAY provide for some small leeway, usually no more than a few minutes, to account for clock skew. Its value is a JSON number representing the number of seconds from 1970-01-01T0:0:0Z as measured in UTC until the date/time. See RFC 3339 [RFC3339] for details regarding date/times in general and UTC in particular.
    public let exp: Int
    
    ///Time at which the JWT was issued. Its value is a JSON number representing the number of seconds from 1970-01-01T0:0:0Z as measured in UTC until the date/time.
    public let iat: Int
    
    ///Time when the End-User authentication occurred. Its value is a JSON number representing the number of seconds from 1970-01-01T0:0:0Z as measured in UTC until the date/time. When a max_age request is made or when auth_time is requested as an Essential Claim, then this Claim is REQUIRED; otherwise, its inclusion is OPTIONAL. (The auth_time Claim semantically corresponds to the OpenID 2.0 PAPE [OpenID.PAPE] auth_time response parameter.)
    public let auth_time: Int?
    
    ///String value used to associate a Client session with an ID Token, and to mitigate replay attacks. The value is passed through unmodified from the Authentication Request to the ID Token. If present in the ID Token, Clients MUST verify that the nonce Claim Value is equal to the value of the nonce parameter sent in the Authentication Request. If present in the Authentication Request, Authorization Servers MUST include a nonce Claim in the ID Token with the Claim Value being the nonce value sent in the Authentication Request. Authorization Servers SHOULD perform no other processing on nonce values used. The nonce value is a case sensitive string.
    public let nonce: String?
    
    ///Authentication Context Class Reference. String specifying an Authentication Context Class Reference value that identifies the Authentication Context Class that the authentication performed satisfied. The value "0" indicates the End-User authentication did not meet the requirements of ISO/IEC 29115 [ISO29115] level 1. Authentication using a long-lived browser cookie, for instance, is one example where the use of "level 0" is appropriate. Authentications with level 0 SHOULD NOT be used to authorize access to any resource of any monetary value. (This corresponds to the OpenID 2.0 PAPE [OpenID.PAPE] nist_auth_level 0.) An absolute URI or an RFC 6711 [RFC6711] registered name SHOULD be used as the acr value; registered names MUST NOT be used with a different meaning than that which is registered. Parties using this claim will need to agree upon the meanings of the values used, which may be context-specific. The acr value is a case sensitive string.
    public let acr: String?

    ///Authentication Methods References. JSON array of strings that are identifiers for authentication methods used in the authentication. For instance, values might indicate that both password and OTP authentication methods were used. The definition of particular values to be used in the amr Claim is beyond the scope of this specification. Parties using this claim will need to agree upon the meanings of the values used, which may be context-specific. The amr value is an array of case sensitive strings.
    public let amr: [String]?
    
    ///Authorized party - the party to which the ID Token was issued. If present, it MUST contain the OAuth 2.0 Client ID of this party. This Claim is only needed when the ID Token has a single audience value and that audience is different than the authorized party. It MAY be included even when the authorized party is the same as the sole audience. The azp value is a case sensitive string containing a StringOrURI value.
    public let azp: String?
    
    public let jwt: JWT
    
    public init?(jwt: JWT) {
        
        self.jwt = jwt
        
        guard
        let issString = jwt.claims["iss"] as? String,
        let iss = URL(string: issString),
        let sub = jwt.claims["sub"] as? String,
        let aud = jwt.claims["aud"] as? String,
        let exp = jwt.claims["exp"] as? Int,
        let iat = jwt.claims["iat"] as? Int
        else {
            
            return nil
        }
        
        self.iss = iss
        self.sub = sub
        self.aud = aud
        self.exp = exp
        self.iat = iat
        
        self.auth_time = jwt.claims["auth_time"] as? Int
        self.nonce = jwt.claims["nonce"] as? String
        self.acr = jwt.claims["acr"] as? String
        self.amr = jwt.claims["amr"] as? [String]
        self.azp = jwt.claims["azp"] as? String
    }
}

//MARK: - RawRepresentable
extension IDToken: RawRepresentable {
    
    public var rawValue: String {
        
        return self.jwt.rawValue
    }
    
    public init?(rawValue: String) {
        
        guard let jwt = JWT(rawValue: rawValue) else {
            
            return nil
        }
        
        self.init(jwt: jwt)
    }
}
