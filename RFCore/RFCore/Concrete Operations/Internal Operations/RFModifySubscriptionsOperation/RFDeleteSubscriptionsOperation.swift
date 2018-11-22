//
//  RFDeleteSubscriptionsOperation.swift
//  RFCore
//
//  Created by David Moore on 8/7/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation
import AWSSNS

/// Deletes subscriptions from a container.
internal class RFDeleteSubscriptionsOperation: RFContainerOperation {

    // MARK: - Properties
    
    /// The subscriptions to delete from to the container.
    open var subscriptionIDs: [RFSubscription.ID]?
    
    /// The block to execute after all of the subscriptions have been deleted.
    open var deleteSubscriptionsCompletionBlock: (([RFSubscription.ID]?, Error?) -> Void)?
    
    /// Operation queue used to execute modification-related operations.
    internal lazy var deleteQueue: OperationQueue = OperationQueue()
    
    // MARK: - Initialization
    
    /// Initializes and returns an operation object.
    public convenience init(subscriptionIDs: [RFSubscription.ID]?) {
        self.init()
        self.subscriptionIDs = subscriptionIDs
    }
    
    /// Initializes and returns an operation object.
    public override init() {
        super.init()
    }
    
    // MARK: - State
    
    override func start() {
        super.start()
        
        guard !isCancelled, let _ = subscriptionIDs else {
            self.deleteSubscriptionsCompletionBlock?(nil, nil)
            return currentState = .finished
        }
        
        fatalError("'RFDeleteSubscriptionsOperation' not implemented.")
        
        /*let queryRequest = AWSSNSListEndpointsByPlatformApplicationInput()!
        
        AWSSNSGetEndpointAttributesInput
        operationalContainer.subscriptionService.getEndpointAttributes(<#T##request: AWSSNSGetEndpointAttributesInput##AWSSNSGetEndpointAttributesInput#>)
        
        operationalContainer.subscriptionService.listEndpoints(byPlatformApplication: <#T##AWSSNSListEndpointsByPlatformApplicationInput#>)
        
        let deleteEndpointRequest = AWSSNSDeleteEndpointInput()!
        deleteEndpointRequest.endpointArn = 
        
        operationalContainer.subscriptionService.deleteEndpoint(<#T##request: AWSSNSDeleteEndpointInput##AWSSNSDeleteEndpointInput#>, completionHandler: <#T##((Error?) -> Void)?##((Error?) -> Void)?##(Error?) -> Void#>)*/
    }
    
    override func cancel() {
        super.cancel()
    }
}
