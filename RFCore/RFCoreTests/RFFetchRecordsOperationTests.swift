//
//  RFFetchRecordsOperationTests.swift
//  RFCoreTests
//
//  Created by David Moore on 7/20/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import XCTest
@testable import RFCore

class RFFetchRecordsOperationTests: XCTestCase {

    // MARK: - Propertiees
    
    var credentialsDelegate = CredentialsDelegate()
    
    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        RFContainer.default.configuration.delegate = credentialsDelegate
    }
    
    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: - Tests
    
    func testEquatableConformance() {
        let lhs = RFFetchRecordsOperation(recordIDs: [RFRecordTests.newRecord().recordID])
        let rhs = RFFetchRecordsOperation()
        rhs.operationID = lhs.operationID
        rhs.fetchQueue = lhs.fetchQueue
        XCTAssertNotEqual(lhs, rhs)
        
        rhs.recordIDs = lhs.recordIDs
        XCTAssertEqual(lhs, rhs)
    }
    
    func testOperation() {
        let queryExpectation = expectation(description: "Query a number of records.")
        let fetchExpectation = expectation(description: "Fetch all of the queried records.")
        
        let queryOperation = RFQueryOperation(query: RFQuery())
        
        queryOperation.queryCompletionBlock = { records, cursor, error in
            XCTAssertNil(error)
            queryExpectation.fulfill()
            
            if let records = records {
                let fetchOperation = RFFetchRecordsOperation(recordIDs: records.map { $0.recordID })
                
                fetchOperation.perRecordProgressBlock = { record, progress in
                    
                }
                
                fetchOperation.perRecordCompletionBlock = { record, recordID, error in
                    XCTAssertNil(error)
                    XCTAssertNotNil(recordID)
                    XCTAssertNotNil(record)
                }
                
                fetchOperation.fetchRecordsCompletionBlock = { recordsByRecordID, error in
                    XCTAssertNil(error)
                    XCTAssertNotNil(recordsByRecordID)
                    
                    if let recordsByRecordID = recordsByRecordID {
                        for record in recordsByRecordID.values {
                            XCTAssertNotNil(record.asset)
                            if let asset = record.asset {
                                XCTAssertTrue(FileManager.default.fileExists(atPath: asset.fileURL.path))
                            }
                        }
                    }
                    
                    fetchExpectation.fulfill()
                }
                
                RFContainer.default.add(fetchOperation)
            } else {
                fetchExpectation.fulfill()
            }
        }
        
        RFContainer.default.add(queryOperation)
        
        waitForExpectations(timeout: 1.0e4)
    }
}
