//
//  RFOperationGroupTests.swift
//  RFCoreTests
//
//  Created by David Moore on 7/20/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import XCTest
@testable import RFCore

class RFOperationGroupTests: XCTestCase {

    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    class func newOperationGroup() -> RFOperationGroup {
        let group = RFOperationGroup()
        group.expectedSendSize = RFOperationGroup.TransferSize.allCases.randomElement()!
        group.expectedReceiveSize = RFOperationGroup.TransferSize.allCases.randomElement()!
        group.name = UUID().uuidString
        
        return group
    }
    
    // MARK: - Tests
    
    func testEquatableConformance() {
        let lhs = RFOperationGroupTests.newOperationGroup()
        let rhs = RFOperationGroup()
        rhs.defaultConfiguration = lhs.defaultConfiguration
        rhs.expectedReceiveSize = lhs.expectedReceiveSize
        rhs.expectedSendSize = lhs.expectedSendSize
        rhs.name = lhs.name
        rhs.operationGroupID = lhs.operationGroupID
        rhs.operations = lhs.operations
        XCTAssertEqual(lhs, rhs)
    }
}
