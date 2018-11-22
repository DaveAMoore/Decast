//
//  RFQueryTests.swift
//  RFCoreTests
//
//  Created by David Moore on 7/20/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import XCTest
@testable import RFCore

class RFQueryTests: XCTestCase {

    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    class func newQuery() -> RFQuery {
        let query = RFQuery(prefix: Bool.random() ? UUID().uuidString : nil,
                            delimiter: Bool.random() ? UUID().uuidString : nil,
                            startAfterRecordID: Bool.random() ? RFRecordTests.newRecord().recordID : nil)
        return query
    }
    
    // MARK: - Tests
    
    func testEquatableConformance() {
        let lhs = RFQueryTests.newQuery()
        let rhs = RFQuery(prefix: lhs.prefix, delimiter: lhs.delimiter, startAfterRecordID: lhs.startAfterRecordID)
        XCTAssertEqual(lhs, rhs)
    }
}
