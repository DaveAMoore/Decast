//
//  RFModifyRecordOperationTests.swift
//  RFCoreTests
//
//  Created by David Moore on 7/20/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import XCTest
@testable import RFCore

class RFModifyRecordOperationTests: XCTestCase {

    // MARK: - Properties
    
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
        let coinFlip = Bool.random()
        let recordsToSave = coinFlip ? (1...Int.random(in: 1...10)).map { _ in RFRecordTests.newRecord() } : nil
        let recordIDsToDelete = !coinFlip ? (1...Int.random(in: 1...10)).map { _ in RFRecordTests.newRecord().recordID } : nil
        let lhs = RFModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
        let rhs = RFModifyRecordsOperation()
        rhs.operationID = lhs.operationID
        rhs.modificationQueue = lhs.modificationQueue
        XCTAssertNotEqual(lhs, rhs)
        
        rhs.recordsToSave = lhs.recordsToSave
        rhs.recordIDsToDelete = lhs.recordIDsToDelete
        XCTAssertEqual(lhs, rhs)
    }
    
    func testSinglePartSaveAndDelete() {
        let recordsToSave = (1...Int.random(in: 1...10)).map { _ -> RFRecord in
            let record = RFRecordTests.newRecord()
            record.asset = RFAssetTests.newDataBackedAsset(withNumberOfBytes: Int.random(in: 1000...10000000))
            return record
        }
        
        let saveExpectation = expectation(description: "Save a single record to the container.")
        saveExpectation.expectedFulfillmentCount = recordsToSave.count
        let completionExpectation = expectation(description: "Modify records operation completes.")
        let deleteExpectation = expectation(description: "Delete all records that were just created.")
        
        let saveOperation = RFModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: nil)
        
        saveOperation.perRecordProgressBlock = { record, progress in
            
        }
        
        saveOperation.perRecordCompletionBlock = { record, error in
            XCTAssertNil(error)
            saveExpectation.fulfill()
        }
        
        saveOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
            XCTAssertNotNil(savedRecords)
            XCTAssertNil(deletedRecordIDs)
            XCTAssertNil(error)
            
            completionExpectation.fulfill()
            
            // Delete the temporary files.
            for record in recordsToSave {
                try! FileManager.default.removeItem(at: record.asset!.fileURL)
            }
            
            if let savedRecords = savedRecords {
                let deleteOperation = RFModifyRecordsOperation(recordsToSave: nil,
                                                               recordIDsToDelete: savedRecords.map { $0.recordID })
                
                deleteOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
                    XCTAssertNil(savedRecords)
                    XCTAssertNotNil(deletedRecordIDs)
                    XCTAssertNil(error)
                    
                    deleteExpectation.fulfill()
                }
                
                RFContainer.default.add(deleteOperation)
            }
        }
        
        RFContainer.default.add(saveOperation)
        
        waitForExpectations(timeout: 4.8e2)
    }
    
    func testMultipartSaveAndDelete() {
        let recordsToSave = (1...Int.random(in: 1...3)).map { _ -> RFRecord in
            let record = RFRecordTests.newRecord()
            record.asset = RFAssetTests.newDataBackedAsset(withNumberOfBytes: Int.random(in: 256000000...300000000))
            return record
        }
        
        let saveExpectation = expectation(description: "Save a single record using multipart to the container.")
        saveExpectation.expectedFulfillmentCount = recordsToSave.count
        
        let completionExpectation = expectation(description: "Modify records operation completes.")
        
        let deleteExpectation = expectation(description: "Delete all records that were just created.")
        
        let saveOperation = RFModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: nil)
        
        saveOperation.perRecordProgressBlock = { record, progress in
            
        }
        
        saveOperation.perRecordCompletionBlock = { record, error in
            XCTAssertNil(error)
            saveExpectation.fulfill()
        }
        
        saveOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
            XCTAssertNotNil(savedRecords)
            XCTAssertNil(deletedRecordIDs)
            XCTAssertNil(error)
            
            completionExpectation.fulfill()
            
            // Delete the temporary files.
            for record in recordsToSave {
                try! FileManager.default.removeItem(at: record.asset!.fileURL)
            }
            
            if let savedRecords = savedRecords {
                let deleteOperation = RFModifyRecordsOperation(recordsToSave: nil,
                                                               recordIDsToDelete: savedRecords.map { $0.recordID })
                
                deleteOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
                    XCTAssertNil(savedRecords)
                    XCTAssertNotNil(deletedRecordIDs)
                    XCTAssertNil(error)
                    
                    deleteExpectation.fulfill()
                }
                
                RFContainer.default.add(deleteOperation)
            }
        }
        
        RFContainer.default.add(saveOperation)
        
        waitForExpectations(timeout: 3.6e3)
    }
}
