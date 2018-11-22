//
//  RFContainerOperation.swift
//  RFCore
//
//  Created by David Moore on 7/17/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

/// The abstract parent class for operations that act on buckets in RFCore.
open class RFContainerOperation: RFOperation {
    
    /// The container that is the target of the operation.
    open var container: RFContainer?
    
    /// Container to use internally.
    internal var operationalContainer: RFContainer {
        guard let container = container else { preconditionFailure("Expected 'container' to be non-nil") }
        return container
    }
    
    /// Boolean value indicating if the operation should use database methods.
    internal var isDatabaseOperation: Bool {
        return operationalContainer.databaseID != nil
    }
    
    /// Returns if the two objects are equal to one another.
    open override func isEqual(_ object: Any?) -> Bool {
        return super.isEqual(object) && container == (object as? RFContainerOperation)?.container
    }
    
    /// Applies a number of properties to the receiver.
    ///
    /// - Parameter operation: The operation from which property values will be taken from.
    internal override func setProperties(basedOn operation: RFOperation) {
        super.setProperties(basedOn: operation)
        
        // Apply the container if it is a container operation.
        if let operation = operation as? RFContainerOperation {
            container = operation.container
        }
    }
}
