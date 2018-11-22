//
//  RFOperation.swift
//  RFCore
//
//  Created by David Moore on 7/17/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

/// The abstract base class for all operations that can be executed.
open class RFOperation: Operation {
    
    // MARK: - Types
    
    /// A collection of properties that describes how an RFOperation should behave.
    open class Configuration: NSObject {
        /// Boolean value indicating whether the operations using this configuration may send data over the cellular network.
        open var allowsCellularAccess: Bool = true
        
        /// Boolean value indicating if the operations using this configuration are long lived.
        open var isLongLived: Bool = false
        
        /// The relative amount of importance of granting system resources to the operations using this configuration.
        open var qualityOfService: QualityOfService = .default
        
        /// The timeout interval to use when waiting for additional data.
        open var timeoutIntervalForRequest: TimeInterval = 60
        
        /// The maximum amount of time that a resource request is allowed to take.
        open var timeoutIntervalForResource: TimeInterval = 6.048E5
        
        /// Returns if the two objects are equal to one another.
        open override func isEqual(_ object: Any?) -> Bool {
            guard let rhs = object as? Configuration else { return false }
            return allowsCellularAccess == rhs.allowsCellularAccess && isLongLived == rhs.isLongLived && qualityOfService == rhs.qualityOfService && timeoutIntervalForRequest == rhs.timeoutIntervalForRequest && timeoutIntervalForResource == rhs.timeoutIntervalForResource
        }
    }
    
    /// Cases that represent the various states of an `RFOperation` at the different points in an operation's lifecycle.
    public enum State: Int {
        case ready
        case executing
        case finished
        
        /// Key path associated with the property the particular case is related to.
        internal var keyPath: KeyPath<RFOperation, Bool> {
            switch self {
            case .ready:
                return \RFOperation.isReady
            case .executing:
                return \RFOperation.isExecuting
            case .finished:
                return \RFOperation.isFinished
            }
        }
    }
    
    /// Operation identifier.
    public typealias ID = String
    
    // MARK: - Properties
    
    /// This defines per-operation configuration settings.
    open var configuration = Configuration()
    
    /// The group this operation is associated with.
    open var group: RFOperationGroup? {
        willSet {
            group?.remove(self)
        } didSet {
            group?.add(self)
        }
    }
    
    /// Quality of service which the operation is executed with.
    open override var qualityOfService: QualityOfService {
        get {
            return configuration.qualityOfService
        } set {
            configuration.qualityOfService = newValue
        }
    }
    
    /// This is an identifier unique to this CKOperation.
    open internal(set) var operationID: ID
    
    /// A Boolean value indicating whether the operation executes its task asynchronously.
    open override var isAsynchronous: Bool {
        return true
    }
    
    /// A Boolean value indicating whether the operation can be performed now.
    open override var isReady: Bool {
        return currentState == .ready
    }
    
    /// A Boolean value indicating whether the operation is currently executing.
    open override var isExecuting: Bool {
        return currentState == .executing
    }
    
    /// A Boolean value indicating whether the operation has finished executing its task.
    open override var isFinished: Bool {
        return currentState == .finished
    }
    
    /// A representation of the operation's current state, relative to boolean properties.
    internal var currentState: State = .ready {
        willSet {
            willChangeValue(for: currentState.keyPath)
            willChangeValue(for: newValue.keyPath)
        } didSet {
            didChangeValue(for: oldValue.keyPath)
            didChangeValue(for: currentState.keyPath)
        }
    }
    
    /// Dispatch queue to use for execution of the operation, if possible.
    internal var executionQueue: DispatchQueue {
        return DispatchQueue.global(qos: configuration.qualityOfService.qosClass)
    }
    
    // MARK: - Initialization
    
    public override init() {
        operationID = UUID().uuidString
        super.init()
    }
    
    /// Applies a number of properties to the receiver.
    ///
    /// - Parameter operation: The operation from which property values will be taken from.
    internal func setProperties(basedOn operation: RFOperation) {
        configuration = operation.configuration
        group = operation.group
    }
    
    // MARK: - Equatability
    
    /// Returns if the two objects are equal to one another.
    open override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? RFOperation else { return false }
        return configuration == rhs.configuration && group == rhs.group && qualityOfService == rhs.qualityOfService && operationID == rhs.operationID && currentState == rhs.currentState
    }
    
    // MARK: - State
    
    open override func start() {
        guard !isExecuting else { preconditionFailure("Operation is already executing") }
    }
    
    open override func cancel() {
        
    }
}
