//
//  RFSaveSubscriptionsOperation.swift
//  RFCore
//
//  Created by David Moore on 8/7/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

/// An operation that saves a number of subscriptions to a particular container.
internal class RFSaveSubscriptionsOperation: RFContainerOperation {
    
    // MARK: - Properties
    
    /// The subscriptions to save to the container.
    open var subscriptions: [RFSubscription]?
    
    /// The block to execute after all of the subscriptions have been saved.
    open var saveSubscriptionsCompletionBlock: (([RFSubscription]?, Error?) -> Void)?
    
    /// Operation queue used to execute modification-related operations.
    internal lazy var saveQueue: OperationQueue = OperationQueue()
    
    // MARK: - Initialization
    
    /// Initializes and returns an operation object.
    public convenience init(subscriptions: [RFSubscription]?) {
        self.init()
        self.subscriptions = subscriptions
    }
    
    /// Initializes and returns an operation object.
    public override init() {
        super.init()
    }
    
    // MARK: - State
    
    override func start() {
        super.start()
        
        guard !isCancelled, let subscriptions = subscriptions else {
            self.saveSubscriptionsCompletionBlock?(nil, nil)
            return currentState = .finished
        }
        
        // Define resultant values.
        let resultsLock = DispatchSemaphore(value: 1)
        var savedSubscriptions: [RFSubscription]?
        var operationalError: RFError?
        
        // Report the final state.
        let blockOperation = BlockOperation { [weak self] in
            self?.saveSubscriptionsCompletionBlock?(savedSubscriptions, operationalError)
            self?.currentState = .finished
        }
        
        // Update the state.
        self.currentState = .executing
        
        for subscription in subscriptions {
            // Configure a save operation.
            let saveOperation = RFSaveSubscriptionOperation(subscription: subscription)
            saveOperation.setProperties(basedOn: self)
            
            // Handle the completion.
            saveOperation.saveSubscriptionCompletionBlock = { savedSubscription, error in
                resultsLock.wait()
                if let savedSubscription = savedSubscription {
                    if savedSubscriptions == nil {
                        savedSubscriptions = [savedSubscription]
                    } else {
                        savedSubscriptions?.append(savedSubscription)
                    }
                }
                RFError.update(&operationalError, withPartialError: error, forItemID: subscription.subscriptionID)
                resultsLock.signal()
            }
            
            // Begin executing the save operation.
            blockOperation.addDependency(saveOperation)
            saveQueue.addOperation(saveOperation)
        }
        
        // Add the block to the queue as well.
        saveQueue.addOperation(blockOperation)
    }
    
    override func cancel() {
        super.cancel()
        
        saveQueue.cancelAllOperations()
        self.currentState = .finished
    }
}
