//
//  RFOperationGroup.swift
//  RFCore
//
//  Created by David Moore on 7/17/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

/// An object that allows RFCore operations to be grouped to align with user actions.
open class RFOperationGroup: NSObject {
    
    // MARK: - Types
    
    public enum TransferSize: Int, CaseIterable {
        case kilobytes
        case megabytes
        case gigabytes
        case tensOfMegabytes
        case tensOfGigabytes
        case hundredsOfMegabytes
        case hundredsOfGigabytes
        case unknown
    }
    
    // MARK: - Properties
    
    /// The default configuration that is applied to operations contained in this group.
    open var defaultConfiguration = RFOperation.Configuration()
    
    /// Estimated size of traffic being downloaded from the Server.
    open var expectedReceiveSize: TransferSize = .unknown
    
    /// Estimated size of traffic being uploaded to the Server.
    open var expectedSendSize: TransferSize = .unknown
    
    /// Describes the user action attributed to the operation group.
    open var name: String?
    
    /// The unique identifier for the operation group.
    open internal(set) var operationGroupID: String
    
    /// Number of elements associated with the operation group.
    open var quantity: Int {
        return operations.count
    }
    
    /// Strong hash table containing the operations that are associated with this group.
    open internal(set) var operations = NSHashTable<RFOperation>()
    
    // MARK: - Initialization
    
    public override init() {
        operationGroupID = UUID().uuidString
        super.init()
    }
    
    // MARK: - Equatability
    
    /// Returns if the two objects are equal to one another.
    open override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? RFOperationGroup else { return false }
        return defaultConfiguration == rhs.defaultConfiguration && expectedReceiveSize == rhs.expectedReceiveSize && expectedSendSize == rhs.expectedSendSize && name == rhs.name && operationGroupID == rhs.operationGroupID && quantity == rhs.quantity && operations == rhs.operations
    }
    
    // MARK: - Operation Tracking
    
    /// Adds an operation by using a weak reference.
    internal func add(_ operation: RFOperation) {
        operations.add(operation)
    }
    
    /// Removes an operation that is currently associated with the group.
    internal func remove(_ operation: RFOperation) {
        operations.remove(operation)
    }
    
    /// Removes all operations currently associated with the group.
    internal func removeAllOperations() {
        operations.removeAllObjects()
    }
}
