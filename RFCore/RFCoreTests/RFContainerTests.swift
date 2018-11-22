//
//  RFContainerTests.swift
//  RFCoreTests
//
//  Created by David Moore on 7/20/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import XCTest
import AWSCognitoIdentityProvider
@testable import RFCore

class RFContainerTests: XCTestCase {

    // MARK: - Properties
    
    var credentialsDelegate = CredentialsDelegate()
    
    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // Assign an appropriate delegate.
        RFContainer.default.configuration.delegate = credentialsDelegate
    }

    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    static func newConfiguration() -> RFContainer.Configuration {
        return RFContainer.Configuration(credentials: RFCredentialsTests.newCredentials(),
                                         region: RFRegion.allCases.randomElement()!)
    }
    
    static func newContainer() -> RFContainer {
        return RFContainer(configuration: newConfiguration(), containerID: UUID().uuidString)
    }
    
    // MARK: - Tests
    
    func testConfigurationEquatableConformance() {
        let lhs = RFContainerTests.newConfiguration()
        let rhs = RFContainer.Configuration(credentials: lhs.credentials, region: lhs.region)
        XCTAssert(lhs == rhs)
    }
    
    func testConfigurationCodableConformance() {
        do {
            let lhs = RFContainerTests.newConfiguration()
            
            let encoder = DictionaryEncoder()
            let dictionary = try encoder.encode(lhs)
            
            let decoder = DictionaryDecoder()
            let rhs = try decoder.decode(RFContainer.Configuration.self, from: dictionary)
            
            XCTAssertEqual(lhs, rhs)
        } catch {
            XCTAssert(false, "Error was thrown")
        }
    }
    
    func testEquatableConformance() {
        let lhs = RFContainerTests.newContainer()
        let rhs = RFContainer(configuration: lhs.configuration, containerID: lhs.containerID)
        
        // Should _not_ be equal due to various intrinsic properties being specific to equal individual container.
        XCTAssertNotEqual(lhs, rhs)
    }
    
    func testQuery() {
        let queryExpectation = expectation(description: "Query using the convienence method.")
        
        RFContainer.default.perform(RFQuery()) { records, error in
            XCTAssertNil(error)
            XCTAssertNotNil(records)
            
            queryExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 120)
    }
    
    func testFetch() {
        let queryExpectation = expectation(description: "Query records using the convienence method.")
        let fetchExpectation = expectation(description: "Fetch a single record using the convienence method.")
        
        RFContainer.default.perform(RFQuery()) { records, error in
            XCTAssertNil(error)
            XCTAssertNotNil(records)
            queryExpectation.fulfill()
            
            if let record = records?.first {
                RFContainer.default.fetch(withRecordID: record.recordID) { fetchedRecord, error in
                    XCTAssertNil(error)
                    XCTAssertNotNil(fetchedRecord)
                    
                    if let fetchedRecord = fetchedRecord {
                        XCTAssertEqual(fetchedRecord.recordID, record.recordID)
                        XCTAssertNotNil(fetchedRecord.asset)
                    }
                    
                    fetchExpectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 120)
    }
    
    func testSaveAndDelete() {
        let saveExpectation = expectation(description: "Save a record using the convienence method.")
        let deleteExpectation = expectation(description: "Delete the saved record using the convienence method.")
        
        // Create a sample record.
        let record = RFRecordTests.newRecord()
        record.asset = RFAssetTests.newDataBackedAsset(withNumberOfBytes: Int.random(in: 1000...10000000))
        
        RFContainer.default.save(record) { savedRecord, error in
            XCTAssertNotNil(savedRecord)
            XCTAssertNil(error)
            saveExpectation.fulfill()
            
            try! FileManager.default.removeItem(at: record.asset!.fileURL)
            
            if let savedRecord = savedRecord {
                RFContainer.default.delete(withRecordID: savedRecord.recordID) { deletedRecordID, error in
                    XCTAssertNil(error)
                    XCTAssertNotNil(deletedRecordID)
                    deleteExpectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 240)
    }
}

class CredentialsDelegate: NSObject, AWSCognitoIdentityInteractiveAuthenticationDelegate, AWSCognitoIdentityPasswordAuthentication {
    
    func startPasswordAuthentication() -> AWSCognitoIdentityPasswordAuthentication {
        return self
    }
    
    func getDetails(_ authenticationInput: AWSCognitoIdentityPasswordAuthenticationInput, passwordAuthenticationCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>) {
        passwordAuthenticationCompletionSource.set(result: AWSCognitoIdentityPasswordAuthenticationDetails(username: "David", password: "Sarah1233"))
    }
    
    func didCompleteStepWithError(_ error: Error?) {
        
    }
}
