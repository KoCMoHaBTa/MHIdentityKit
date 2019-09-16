//
//  JWTTests.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 19.07.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import MHIdentityKit

class JWTTests: XCTestCase {
    
    func testJWSType() {
        
        //https://tools.ietf.org/html/draft-ietf-jose-json-web-signature-41#section-3.3
        let jws = "eyJ0eXAiOiJKV1QiLA0KICJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ.dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        
        XCTAssertEqual(JWTType(jwt: jws), .JWS)
    }
    
    func testJWEType() {
        
        //https://tools.ietf.org/html/draft-ietf-jose-json-web-encryption-40#section-3.3
        let jwe = "eyJhbGciOiJSU0EtT0FFUCIsImVuYyI6IkEyNTZHQ00ifQ.OKOawDo13gRp2ojaHV7LFpZcgV7T6DVZKTyKOMTYUmKoTCVJRgckCL9kiMT03JGeipsEdY3mx_etLbbWSrFr05kLzcSr4qKAq7YN7e9jwQRb23nfa6c9d-StnImGyFDbSv04uVuxIp5Zms1gNxKKK2Da14B8S4rzVRltdYwam_lDp5XnZAYpQdb76FdIKLaVmqgfwX7XWRxv2322i-vDxRfqNzo_tETKzpVLzfiwQyeyPGLBIO56YJ7eObdv0je81860ppamavo35UgoRdbYaBcoh9QcfylQr66oc6vFWXRcZ_ZT2LawVCWTIy3brGPi6UklfCpIMfIjf7iGdXKHzg.48V1_ALb6US04U3b.5eym8TW_c8SuK0ltJ3rpYIzOeDQz7TALvtu6UG9oMo4vpzs9tX_EFShS8iB7j6jiSdiwkIr3ajwQzaBtQD_A.XFBoMYUZodetZdvTiFvSkQ"
        
        XCTAssertEqual(JWTType(jwt: jwe), .JWE)
    }
    
    func testBase64UrlEncoding() {
        
        //>>>???aaa --> Pj4+Pz8/YWFh --> Pj4-Pz8_YWFh
        XCTAssertEqual(">>>???aaa".data(using: .utf8)!.base64UrlEncodedString(removePadding: false), "Pj4-Pz8_YWFh")
        XCTAssertEqual(">>>???aaa".data(using: .utf8)!.base64UrlEncodedString(removePadding: true), "Pj4-Pz8_YWFh")
        XCTAssertEqual(String(data: Data(base64UrlEncoded: "Pj4-Pz8_YWFh")!, encoding: .utf8), ">>>???aaa")
        XCTAssertEqual(String(data: Data(base64UrlEncoded: "Pj4-Pz8_YWFh")!, encoding: .utf8), ">>>???aaa")
        
        //>>>???aa  --> Pj4+Pz8/YWE= --> Pj4-Pz8_YWE=
        XCTAssertEqual(">>>???aa".data(using: .utf8)!.base64UrlEncodedString(removePadding: false), "Pj4-Pz8_YWE=")
        XCTAssertEqual(">>>???aa".data(using: .utf8)!.base64UrlEncodedString(removePadding: true), "Pj4-Pz8_YWE")
        XCTAssertEqual(String(data: Data(base64UrlEncoded: "Pj4-Pz8_YWE=")!, encoding: .utf8), ">>>???aa")
        XCTAssertEqual(String(data: Data(base64UrlEncoded: "Pj4-Pz8_YWE=")!, encoding: .utf8), ">>>???aa")
        XCTAssertEqual(String(data: Data(base64UrlEncoded: "Pj4-Pz8_YWE")!, encoding: .utf8), ">>>???aa")
        XCTAssertEqual(String(data: Data(base64UrlEncoded: "Pj4-Pz8_YWE")!, encoding: .utf8), ">>>???aa")
        
        //>>>???a   --> Pj4+Pz8/YQ== --> Pj4-Pz8_YQ==
        XCTAssertEqual(">>>???a".data(using: .utf8)!.base64UrlEncodedString(removePadding: false), "Pj4-Pz8_YQ==")
        XCTAssertEqual(">>>???a".data(using: .utf8)!.base64UrlEncodedString(removePadding: true), "Pj4-Pz8_YQ")
        XCTAssertEqual(String(data: Data(base64UrlEncoded: "Pj4-Pz8_YQ==")!, encoding: .utf8), ">>>???a")
        XCTAssertEqual(String(data: Data(base64UrlEncoded: "Pj4-Pz8_YQ==")!, encoding: .utf8), ">>>???a")
        XCTAssertEqual(String(data: Data(base64UrlEncoded: "Pj4-Pz8_YQ")!, encoding: .utf8), ">>>???a")
        XCTAssertEqual(String(data: Data(base64UrlEncoded: "Pj4-Pz8_YQ")!, encoding: .utf8), ">>>???a")
    }
}
