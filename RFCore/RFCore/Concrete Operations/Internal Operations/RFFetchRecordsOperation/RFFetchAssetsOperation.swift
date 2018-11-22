//
//  RFFetchAssetsOperation.swift
//  RFCore
//
//  Created by David Moore on 8/26/18.
//

import Foundation

/// An operation used to retrieve assets from RFCore.
open class RFFetchAssetsOperation: RFContainerOperation {
    
    // MARK: - Properties
    
    /// The array of IDs corresponding to the assets to fetch.
    open var assetIDs: [RFAsset.ID]?
    
    /// The block to execute with progress information for individual assets.
    open var perAssetProgressBlock: ((RFAsset.ID, Double) -> Void)?
    
    /// The block to execute when the results of a single asset are available.
    open var perAssetCompletionBlock: ((RFAsset?, RFAsset.ID?, Error?) -> Void)?
    
    /// The block to execute after all assets are fetched or have received appropriate errors.
    open var fetchAssetsCompletionBlock: (([RFAsset.ID: RFAsset]?, Error?) -> Void)?
    
    /// Queue used for running a number of concurrent fetches.
    internal lazy var fetchQueue: OperationQueue = {
        // Create a new queue that has a particular concurrency allowance.
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 75
        return queue
    }()
    
    // MARK: - Initialization
    
    /// Initializes and returns an operation object configured to fetch the assets with the specified IDs.
    public convenience init(assetIDs: [RFAsset.ID]) {
        self.init()
        self.assetIDs = assetIDs
    }
    
    public override init() {
        super.init()
    }
    
    // MARK: - State
    
    open override func start() {
        super.start()
        
        guard !isCancelled, let assetIDs = assetIDs else {
            self.fetchAssetsCompletionBlock?(nil, nil)
            return currentState = .finished
        }
        
        // Update the state.
        currentState = .executing
        
        // Define a lock and asset dictionary.
        let resultsLock = DispatchSemaphore(value: 1)
        var assetsByAssetID: [RFAsset.ID: RFAsset]?
        var operationalError: RFError?
        
        // Create a block that culminates the records in one.
        let blockOperation = BlockOperation { [weak self] in
            self?.fetchAssetsCompletionBlock?(assetsByAssetID, operationalError)
            self?.currentState = .finished
            
            // Try to remove the temporary asset files.
            if let assetsByAssetID = assetsByAssetID {
                for asset in assetsByAssetID.values {
                    try? FileManager.default.removeItem(at: asset.fileURL)
                }
            }
        }
        
        // Enumerate the record identifiers.
        for assetID in assetIDs {
            // Create a new fetch operation.
            let fetchOperation = RFFetchAssetOperation(assetID: assetID)
            fetchOperation.setProperties(basedOn: self)
            fetchOperation.transferUtility = operationalContainer.transferUtility
            
            // Update for progress changes.
            fetchOperation.progressBlock = { [weak self] progress in
                self?.perAssetProgressBlock?(assetID, progress)
            }
            
            // Handle the result.
            fetchOperation.fetchAssetCompletionBlock = { [weak self] fetchedAsset, error in
                resultsLock.wait()
                if let fetchedAsset = fetchedAsset {
                    // Create the dictionary if required.
                    if assetsByAssetID == nil {
                        assetsByAssetID = [assetID: fetchedAsset]
                    } else {
                        assetsByAssetID?[assetID] = fetchedAsset
                    }
                }
                RFError.update(&operationalError, withPartialError: error, forItemID: assetID)
                resultsLock.signal()
                
                // Call the completion block.
                self?.perAssetCompletionBlock?(fetchedAsset, assetID, error)
            }
            
            // Make the block dependent on this fetch.
            blockOperation.addDependency(fetchOperation)
            
            // Start the fetch operation.
            fetchQueue.addOperation(fetchOperation)
        }
        
        // Add the block operation to be performed later.
        fetchQueue.addOperation(blockOperation)
    }
    
    open override func cancel() {
        super.cancel()
        
        // Use the queue to cancel everything.
        fetchQueue.cancelAllOperations()
        currentState = .finished
    }
}

