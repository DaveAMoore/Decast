//
//  RFSaveAssetsOperation.swift
//  RFCore
//
//  Created by David Moore on 7/27/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation
import AWSS3
import RFAssetInternal

/// An operation that saves a number of assets.
internal class RFSaveAssetsOperation: RFContainerOperation {
    
    // MARK: - Properties
    
    /// The assets to save to the database.
    open var assets: [RFAsset]?
    
    /// Transfer utility to use for uploading the assets. Default value is derived through accessing `operationalContainer.transferUtility`.
    internal var transferUtility: AWSS3TransferUtility?
    
    /// The block to execute with progress information for an individual asset.
    open var perAssetProgressBlock: ((RFAsset, Double) -> Void)?
    
    /// The block to execute when the save results of a single asset are known.
    open var perAssetCompletionBlock: ((RFAsset, Error?) -> Void)?
    
    /// The block to execute after the status of all changes is known.
    open var saveAssetsCompletionBlock: (([RFAsset]?, Error?) -> Void)?
    
    /// Queue used for running a number of concurrent saves.
    private lazy var saveQueue: OperationQueue = {
        // Create a new queue that has a particular concurrency allowance.
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 75
        return queue
    }()
    
    // MARK: - Initialization
    
    /// Initializes and returns an operation object.
    public convenience init(assets: [RFAsset]?) {
        self.init()
        self.assets = assets
    }
    
    /// Initializes and returns an operation object.
    public override init() {
        super.init()
    }
    
    // MARK: - State
    
    open override func start() {
        super.start()
        
        guard !isCancelled, let assets = assets else {
            saveAssetsCompletionBlock?(nil, nil)
            return currentState = .finished
        }
        
        // Declare a collection of saved records and a lock for mutation.
        let resultsLock = DispatchSemaphore(value: 1)
        var savedAssets: [RFAsset]?
        var operationalError: RFError?
        
        // Create a block to be executed after all the records have been saved.
        let blockOperation = BlockOperation { [weak self] in
            self?.saveAssetsCompletionBlock?(savedAssets, operationalError)
            self?.currentState = .finished
        }
        
        // Create an operation for each individual record.
        for asset in assets {
            // Create and configure a save operation for this particular record.
            let saveOperation = RFSaveAssetOperation(asset: asset)
            saveOperation.setProperties(basedOn: self)
            saveOperation.transferUtility = transferUtility
            
            // Handle the progress reporting.
            saveOperation.progressBlock = { [weak self] asset, progress in
                self?.perAssetProgressBlock?(asset, progress)
            }
            
            // Handle the completion call.
            saveOperation.saveAssetCompletionBlock = { [weak self] _asset, error in
                // Add the record to the appropriate collection.
                resultsLock.wait()
                if let _asset = _asset {
                    if savedAssets == nil {
                        savedAssets = [_asset]
                    } else {
                        savedAssets?.append(_asset)
                    }
                }
                RFError.update(&operationalError, withPartialError: error, forItemID: asset.assetID)
                resultsLock.signal()
                
                self?.perAssetCompletionBlock?(asset, error)
            }
            
            // Make the block dependent on this save operation.
            blockOperation.addDependency(saveOperation)
            
            // Start executing the operation.
            saveQueue.addOperation(saveOperation)
        }
        
        // Add the block to the queue for execution when its dependencies have finished.
        saveQueue.addOperation(blockOperation)
    }
    
    open override func cancel() {
        super.cancel()
    }
}
