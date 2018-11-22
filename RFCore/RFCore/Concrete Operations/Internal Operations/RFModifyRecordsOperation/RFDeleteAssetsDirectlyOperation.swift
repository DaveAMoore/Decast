//
//  RFDeleteAssetsDirectlyOperation.swift
//  RFCore
//
//  Created by David Moore on 8/12/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation
import AWSS3

/// An operation that deletes assets directly without any recursion.
internal class RFDeleteAssetsDirectlyOperation: RFContainerOperation {

    // MARK: - Properties
    
    /// The IDs of the assets to delete permanently from the database.
    open var assetIDs: [RFAsset.ID]?
    
    /// The block to execute after the status of all changes is known.
    open var deleteAssetsDirectlyCompletionBlock: (([RFAsset.ID]?, Error?) -> Void)?
    
    // MARK: - Initialization
    
    /// Initializes and returns an operation object.
    public convenience init(assetIDs: [RFAsset.ID]?) {
        self.init()
        self.assetIDs = assetIDs
    }
    
    /// Initializes and returns an operation object.
    public override init() {
        super.init()
    }
    
    // MARK: - State
    
    open override func start() {
        super.start()
        
        guard !isCancelled, let assetIDs = assetIDs, !assetIDs.isEmpty else {
            self.deleteAssetsDirectlyCompletionBlock?(nil, nil)
            return currentState = .finished
        }
        
        // Sort the record identifiers to ensure folders are deleted last.
        let sortedRecordIDs = assetIDs.lazy.sorted(by: { !$0.isFolder && $1.isFolder })
        
        // Create a remove object and map the record identifiers to S3 object identifiers.
        let remove = AWSS3Remove()!
        remove.objects = sortedRecordIDs.map { assetID in
            let identifier = AWSS3ObjectIdentifier()!
            identifier.key = assetID.assetName
            
            return identifier
        }
        
        // Configure the delete request.
        let deleteRequest = AWSS3DeleteObjectsRequest()!
        deleteRequest.bucket = operationalContainer.containerID
        deleteRequest.remove = remove
        
        // Start the delete request.
        let deleteTask = operationalContainer.storageService.deleteObjects(deleteRequest)
        
        // Update the state.
        currentState = .executing
        
        // Assign a continuation block.
        deleteTask.continueWith { [weak self] task -> Any? in
            // Process the results.
            let deletedAssetIDs = task.result?.deleted?.map { RFAsset.ID(assetName: $0.key!) }
            self?.deleteAssetsDirectlyCompletionBlock?(deletedAssetIDs, task.error)
            
            // Update state.
            self?.currentState = .finished
            
            return nil
        }
    }
    
    open override func cancel() {
        super.cancel()
    }
}
