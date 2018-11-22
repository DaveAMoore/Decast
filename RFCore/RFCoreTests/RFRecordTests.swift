//
//  RFRecordTests.swift
//  RFCoreTests
//
//  Created by David Moore on 7/20/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import XCTest
@testable import RFCore

class RFRecordTests: XCTestCase {

    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    static func newRecord() -> RFRecord {
        let record = RFRecord(recordID: RFRecord.ID(recordName: UUID().uuidString))
        if Bool.random() { record.asset = RFAssetTests.newAsset() }
        
        return record
    }
    
    // MARK: - Tests
    
    func testIDEquatableConformance() {
        let lhs = RFRecord.ID(recordName: UUID().uuidString)
        let rhs = RFRecord.ID(recordName: lhs.recordName)
        XCTAssertEqual(lhs, rhs)
    }
    
    func testEquatableConformance() {
        let lhs = RFRecordTests.newRecord()
        let rhs = RFRecord(recordID: lhs.recordID)
        rhs.asset = lhs.asset
        XCTAssertEqual(lhs, rhs)
    }
}
