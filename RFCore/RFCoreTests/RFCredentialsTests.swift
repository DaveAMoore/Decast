//
//  RFCredentialsTests.swift
//  RFCoreTests
//
//  Created by David Moore on 7/24/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import XCTest
@testable import RFCore

class RFCredentialsTests: XCTestCase {

    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    static func newCredentials() -> RFCredentials {
        return RFCredentials(applicationClientID: UUID().uuidString, applicationClientSecret: UUID().uuidString,
                             poolID: UUID().uuidString, identityPoolID: UUID().uuidString,
                             region: RFRegion.allCases.randomElement()!)
    }
    
    // MARK: - Tests
    
    func testEquatableConformance() {
        let lhs = RFCredentialsTests.newCredentials()
        let rhs = RFCredentials(applicationClientID: lhs.applicationClientID,
                                applicationClientSecret: lhs.applicationClientSecret, poolID: lhs.poolID,
                                identityPoolID: lhs.identityPoolID, region: lhs.region)
        XCTAssertTrue(lhs == rhs)
    }
    
    func testCodableConformance() {
        do {
            let lhs = RFCredentialsTests.newCredentials()
            
            let encoder = DictionaryEncoder()
            let dictionary = try encoder.encode(lhs)
            
            let decoder = DictionaryDecoder()
            let rhs = try decoder.decode(RFCredentials.self, from: dictionary)
            
            XCTAssertEqual(lhs, rhs)
        } catch {
            XCTAssert(false, "An error was thrown")
        }
    }
}
