//
//  RFQueryOperationTests.swift
//  RFCoreTests
//
//  Created by David Moore on 7/20/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import XCTest
@testable import RFCore

class RFQueryOperationTests: XCTestCase {

    // MARK: - Properties
    
    /// Delegate to use for password authentication.
    lazy var credentialsDelegate = CredentialsDelegate()
    
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
        let lhs = RFQueryOperation()
        lhs.query = RFQueryTests.newQuery()
        let rhs = RFQueryOperation()
        rhs.operationID = lhs.operationID
        XCTAssertNotEqual(lhs, rhs)
        
        rhs.query = lhs.query
        XCTAssertEqual(lhs, rhs)
    }
    
    func testOperation() {
        let queryExpectation = expectation(description: "Query all records")
        
        func performQuery(_ query: RFQuery?, orFollow cursor: RFQueryOperation.Cursor?) {
            let queryOperation = RFQueryOperation()
            queryOperation.query = query
            queryOperation.cursor = cursor
            
            queryOperation.queryCompletionBlock = { records, cursor, error in
                XCTAssertNil(error)
                if let records = records { XCTAssertFalse(records.isEmpty) }
                
                if let cursor = cursor {
                    performQuery(nil, orFollow: cursor)
                } else {
                    queryExpectation.fulfill()
                }
            }
            
            RFContainer.default.add(queryOperation)
        }
        
        performQuery(RFQuery(), orFollow: nil)
        
        waitForExpectations(timeout: 120)
    }
}
