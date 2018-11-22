//
//  RFSaveSubscriptionOperation.swift
//  RFCore
//
//  Created by David Moore on 8/7/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation
import AWSSNS

/// An operation to save a subscription to a container.
internal class RFSaveSubscriptionOperation: RFContainerOperation {
    
    // MARK: - Properties
    
    /// The subscription to save to the container.
    open var subscription: RFSubscription?
    
    /// The block to execute after the subscription has been saved.
    open var saveSubscriptionCompletionBlock: ((RFSubscription?, Error?) -> Void)?
    
    /// Operation queue used to execute modification-related operations.
    internal lazy var saveQueue: OperationQueue = OperationQueue()
    
    // MARK: - Initialization
    
    /// Initializes and returns an operation object.
    public convenience init(subscription: RFSubscription?) {
        self.init()
        self.subscription = subscription
    }
    
    /// Initializes and returns an operation object.
    public override init() {
        super.init()
    }
    
    // MARK: - State
    
    override func start() {
        super.start()
        
        guard !isCancelled, let subscriptionID = subscription?.subscriptionID else {
            self.saveSubscriptionCompletionBlock?(nil, nil)
            return currentState = .finished
        }
        
        // Configure an endpoint create action.
        let createEndpointInput = AWSSNSCreatePlatformEndpointInput()!
        createEndpointInput.token = subscription?.deviceToken
        createEndpointInput.platformApplicationArn = operationalContainer.operationalSubscriptionZoneID
        
        // Update the state.
        currentState = .executing
        
        // Create the platform endpoint.
        operationalContainer.subscriptionService.createPlatformEndpoint(createEndpointInput) { [weak self] createEndpointResponse, error in
            guard let strongSelf = self else { return }
            
            guard error == nil, let endpointARN = createEndpointResponse?.endpointArn else {
                strongSelf.saveSubscriptionCompletionBlock?(nil, error)
                strongSelf.currentState = .finished
                return
            }
            
            // Configure a subscription input.
            let subscribeInput = AWSSNSSubscribeInput()!
            subscribeInput.topicArn = subscriptionID
            subscribeInput.endpoint = endpointARN
            subscribeInput.protocols = "application"
            
            // Attempt to subscribe to the topic.
            strongSelf.operationalContainer.subscriptionService.subscribe(subscribeInput) { subscribeResponse, error in
                strongSelf.saveSubscriptionCompletionBlock?(error == nil ? strongSelf.subscription : nil, error)
                strongSelf.currentState = .finished
            }
        }
    }

    override func cancel() {
        super.cancel()
    }
}
