//
//  URLEncodingUtilities.swift
//  https://gist.github.com/KoCMoHaBTa/05396e94ed84cb70eb5abd0c91b8452f
//
//  Created by Milen Halachev on 7/11/17.
//  Copyright © 2016 Milen Halachev. All rights reserved.
//

import Foundation

//MARK: - Dictionary + URL Encoding

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
        result = String(result[index ..< result.endIndex])
        
        return result
    }
    
    var urlEncodedParametersData: Data? {
        
        return self.urlEncodedParametersString.data(using: .utf8)
    }
}

//MARK: - String + URL Encoding

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

//MARK: - Data + URL Encoding

extension Data {
    
    var urlDecodedParameters: [String: String]? {
        
        return String(data: self, encoding: .utf8)?.urlDecodedParameters
    }
}

//MARK: - URL Operators

func +(lhs: URL, rhs: String) -> URL {
    
    return lhs.appendingPathComponent(rhs)
}

infix operator +? : AdditionPrecedence
func +?(lhs: URL, rhs: [String: Any]) -> URL? {
    
    var components = URLComponents(url: lhs, resolvingAgainstBaseURL: true)
    components?.percentEncodedQuery = rhs.urlEncodedParametersString
    
    return components?.url
}

infix operator +?! : AdditionPrecedence
func +?!(lhs: URL, rhs: [String: Any]) -> URL {
    
    return (lhs +? rhs)!
}
