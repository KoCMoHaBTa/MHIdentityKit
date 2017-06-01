//
//  XCTestExtensions.swift
//  https://gist.github.com/KoCMoHaBTa/4ba07984d7c95822bc05
//
//  Created by Milen Halachev on 3/18/16.
//  Copyright © 2016 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {
    
    ///Performs an expectation with a given description, timeout and handler. You should fulfil the expectation within the handler in the given timeout timeframe
    public func performExpectation(description: String = "XCTestCase Default Expectation", timeout: TimeInterval = 2, handler: (_ expectation: XCTestExpectation) -> Void) {
        
        let expectation = self.expectation(description: description)
        handler(expectation)
        
        self.waitForExpectations(timeout: timeout, handler: { (error) -> Void in
            
            XCTAssertNil(error, "Expectation Error")
        })
    }
}

extension XCTestExpectation {
    
    private struct AssociatedKeys {
        
        static var conditionsKey = "XCTestExpectation.AssociatedKeys.conditionsKey"
    }
    
    public private(set) var conditions: [String: Bool] {
        
        get {
            
            return objc_getAssociatedObject(self, &AssociatedKeys.conditionsKey) as? [String: Bool] ?? [:]
        }
        
        set {
            
            objc_setAssociatedObject(self, &AssociatedKeys.conditionsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var areAllConditionsFulfulled: Bool {
        
        for state in Array(self.conditions.values) {
            
            if state == false {
                
                return false
            }
        }
        
        return true
    }
    
    public func add(conditions: [String]) {
        
        conditions.forEach { (condition) -> () in
            
            self.conditions[condition] = false
        }
    }
    
    public func fulfill(condition: String) {
        
        XCTAssertNotNil(self.conditions[condition], "Cannot fulfil a non-exiting condition: \"\(condition)\"")
        
        guard self.conditions[condition] == false else {
            
            XCTFail("Cannot fulfil condition again - \(condition)")
            return
        }
        
        self.conditions[condition] = true
        
        guard self.areAllConditionsFulfulled else {
            
            return
        }
        
        self.fulfill()
    }
}

extension XCTestExpectation {
    
    ///Fulfils the receiver upon throwing the provided Equatable Error object within the handler.
    public func fulfilOnThrowing<E>(_ expectedError: E, _ errorThrowableCode: () throws -> Void) where E: Error, E: Equatable {
        
        do {
            
            try errorThrowableCode()
        }
        catch let error as E {
            
            XCTAssertEqual(error, expectedError)
            self.fulfill()
            return
        }
        catch {
            
            XCTFail()
        }
        
        XCTFail()
    }
    
    ///Fulfils the receiver upon throwing the provided Error object within the handler. The equality condition is met by comparing the localizedDescription of the expected error and the error thrown.
    public func fulfilOnThrowing<E>(_ expectedError: E, _ errorThrowableCode: () throws -> Void) where E: Error {
        
        do {
            
            try errorThrowableCode()
        }
        catch {
            
            XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
            self.fulfill()
            return
        }
        
        XCTFail()
    }
    
    ///Fulfiles the receicver upon throwin any kind of error within the handler.
    public func fulfilOnThrowing(_ errorThrowableCode: () throws -> Void) {
        
        do {
            
            try errorThrowableCode()
        }
        catch {
            
            self.fulfill()
            return
        }
        
        XCTFail()
    }
    
    ///Fulfils the receiver if there is no error thrown withing the handler
    public func fulfilUnlessThrowing(_ errorThrowableCode: () throws -> Void) {
        
        do {
            
            try errorThrowableCode()
        }
        catch {
            
            XCTFail()
            return
        }
        
        self.fulfill()
    }
}
