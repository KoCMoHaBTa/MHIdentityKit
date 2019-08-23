//
//  Data+Base64UrlEncoding.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 19.07.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation

//https://tools.ietf.org/html/rfc4648#section-5
//https://tools.ietf.org/html/draft-ietf-jose-json-web-signature-41#appendix-C
extension Data {
    
    public func base64UrlEncodedString(removePadding: Bool = true) -> String {
        
        var string = self.base64EncodedString()
        string = string.replacingOccurrences(of: "+", with: "-")
        string = string.replacingOccurrences(of: "/", with: "_")
        
        if removePadding {
            
            string = string.replacingOccurrences(of: "=", with: "")
        }
        
        return string
    }
    
    public init?(base64UrlEncoded: String) {
        
        var string = base64UrlEncoded
        string = string.replacingOccurrences(of: "-", with: "+")
        string = string.replacingOccurrences(of: "_", with: "/")
        
        let paddingCount = 4 - string.count % 4
        
        //because padding is not required, add it if missing
        if paddingCount < 4 {
            
            let padding = String(repeating: "=", count: paddingCount)
            string += padding
        }
        
        self.init(base64Encoded: string)
    }
}
