//
//  MHIdentityKitTests.swift
//  MHIdentityKitTests
//
//  Created by Milen Halachev on 4/11/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import XCTest
@testable import MHIdentityKit

class MHIdentityKitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
//    func testExample() {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//        
//        let url = URL(string: "https://api-vapt-int.onebigsplash.com/feed/newsfeed")!
//        let request = URLRequest(url: url)
//        
//        let tokenUrl = URL(string: "https://account-vapt-int.onebigsplash.com/connect/token")!
//        let clientID = "introclient"
//        let secret = "intsecret"
//        let username = "admin"
//        let password = "123456"
//        let flow = ResourceOwnerPasswordCredentialsGrantFlow(tokenEndpoint: tokenUrl, clientID: clientID, secret: secret, username: username, password: password)
//        
////        self.performExpectation { (expectation) in
////            
////
////
////            
////            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
////                
////                let string = String(data: data ?? Data(), encoding: .utf8)
////                print("")
////            }
////            
////            task.resume()
////        }
//        
//        self.performExpectation { (expectation) in
//            
//            flow.authorize(request: request) { (request, error) in
//                
//                XCTAssertNotNil(error)
//                
//                if case Optional.some(MHIdentityKitError.authorizationFailed(reason: .clientNotAuthenticated)) = error {} else { XCTFail() }
//                
//                expectation.fulfill()
//            }
//        }
//        
//        self.performExpectation { (expectation) in
//            
//            flow.authenticate(handler: { (tokenResponse, error) in
//                
//                print("")
//            })
//        }
//    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
