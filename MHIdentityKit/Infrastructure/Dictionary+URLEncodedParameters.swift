//
//  Dictionary+URLEncodedParameters.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 4/12/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

extension Dictionary {
    
    private func urlEncode(_ string: String) -> String {
        
        var allowedCharacter = CharacterSet.urlQueryAllowed
        allowedCharacter.remove(charactersIn: "!@#$%&*()+'\";:=,/?[] ")
        
        let result = string.addingPercentEncoding(withAllowedCharacters: allowedCharacter)
        return result ?? string
    }
    
    private func urlEncode(_ object: Any) -> String {
        
        return self.urlEncode(String(describing: object))
    }
    
    var urlEncodedParametersString: String {
        
        var result = self.reduce("") { (result, element) -> String in
            
            let key = self.urlEncode(element.key)
            let value = self.urlEncode(element.value)
            
            let result = result + "&" + key + "=" + value
            return result
        }
        
        //remove the first `&` character
        let index = result.index(result.startIndex, offsetBy: 1)
        result = result.substring(from: index)

        return result
    }
    
    var urlEncodedParametersData: Data? {
        
        return self.urlEncodedParametersString.data(using: .utf8)
    }
}

extension String {
    
    var urlDecodedParameters: [String: String] {
        
        let pairs = self.components(separatedBy: "&")
        let parameters = pairs.reduce([:]) { (result, pair) -> [String: String] in
            
            let components = pair.components(separatedBy: "=")
            
            guard
            components.count == 2,
            let key = components.first?.removingPercentEncoding,
            let value = components.last?.removingPercentEncoding
            else {
                
                return result
            }
            
            var result = result
            result[key] = value
            return result
        }
        
        return parameters
    }
}

extension Data {
    
    var urlDecodedParameters: [String: String]? {
        
        return String(data: self, encoding: .utf8)?.urlDecodedParameters
    }
}
