//
//  RFModifySubscriptionsOperation.swift
//  RFCore
//
//  Created by David Moore on 8/1/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

/// An operation for modifying one or more existing subscription objects.
open class RFModifySubscriptionsOperation: RFContainerOperation {
    
    // MARK: - Properties
    
    /// The subscriptions to save to the container.
    open var subscriptionsToSave: [RFSubscription]?
    
    /// The subscriptions to delete from to the container.
    open var subscriptionIDsToDelete: [RFSubscription.ID]?
    
    /// The block to execute after all of the modifications have been performed.
    open var modifySubscriptionsCompletionBlock: (([RFSubscription]?, [RFSubscription.ID]?, Error?) -> Void)?
    
    /// Operation queue used to execute modification-related operations.
    internal lazy var modificationQueue: OperationQueue = OperationQueue()
    
    // MARK: - Initialization
    
    /// Initializes and returns an operation object.
    public convenience init(subscriptionsToSave: [RFSubscription]?, subscriptionIDsToDelete: [RFSubscription.ID]?) {
        self.init()
        self.subscriptionsToSave = subscriptionsToSave
        self.subscriptionIDsToDelete = subscriptionIDsToDelete
    }
    
    /// Initializes and returns an operation object.
    public override init() {
        super.init()
    }
    
    // MARK: - State
    
    open override func start() {
        super.start()
        
        guard !isCancelled else {
            self.modifySubscriptionsCompletionBlock?(nil, nil, nil)
            return currentState = .finished
        }
        
        // Update the state.
        currentState = .executing
        
        // Define resultant values.
        let resultsLock = DispatchSemaphore(value: 1)
        var savedSubscriptions: [RFSubscription]?
        var deletedSubscriptionIDs: [RFSubscription.ID]?
        var operationalError: RFError?
        
        // Return the results.
        let blockOperation = BlockOperation { [weak self] in
            self?.modifySubscriptionsCompletionBlock?(savedSubscriptions, deletedSubscriptionIDs, operationalError)
            self?.currentState = .finished
        }
        
        // Configure a save operation.
        let saveOperation = RFSaveSubscriptionsOperation(subscriptions: subscriptionsToSave)
        saveOperation.setProperties(basedOn: self)
        
        // When the operation is complete update the error and the saved subscriptions array.
        saveOperation.saveSubscriptionsCompletionBlock = { [weak self] _savedSubscriptions, error in
            resultsLock.wait()
            savedSubscriptions = _savedSubscriptions
            RFError.update(&operationalError, withPartialError: error, forItemID: self?.subscriptionsToSave)
            resultsLock.signal()
        }
        
        // Execute the save operation.
        blockOperation.addDependency(saveOperation)
        modificationQueue.addOperation(saveOperation)
        
        // Configure a delete operation.
        let deleteOperation = RFDeleteSubscriptionsOperation(subscriptionIDs: subscriptionIDsToDelete)
        deleteOperation.setProperties(basedOn: self)
        
        // Handle the completion.
        deleteOperation.deleteSubscriptionsCompletionBlock = { [weak self] _deletedSubscriptionIDs, error in
            resultsLock.wait()
            deletedSubscriptionIDs = _deletedSubscriptionIDs
            RFError.update(&operationalError, withPartialError: error, forItemID: self?.subscriptionIDsToDelete)
            resultsLock.signal()
        }
        
        // Add the delete operation.
        blockOperation.addDependency(deleteOperation)
        modificationQueue.addOperation(deleteOperation)
        
        // Add the block operation.
        modificationQueue.addOperation(blockOperation)
    }
    
    open override func cancel() {
        super.cancel()
    }
}
