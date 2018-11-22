//
//  RFDeleteAssetsOperation.swift
//  RFCore
//
//  Created by David Moore on 7/27/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

/// An operation that deletes a given collection of assets.
internal class RFDeleteAssetsOperation: RFContainerOperation {
    
    // MARK: - Properties
    
    /// The IDs of the assets to delete permanently from the storage container.
    open var assetIDs: [RFAsset.ID]?
    
    /// A boolean value indicating if the operation should delete folders without deleting their contents recursively.
    open var shouldDeleteFoldersImmediately: Bool = false
    
    /// The block to execute after the status of all changes is known.
    open var deleteAssetsCompletionBlock: (([RFAsset.ID]?, Error?) -> Void)?
    
    /// Queue used for deleting assets.
    internal lazy var deleteQueue = OperationQueue()
    
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
        
        // Create a lazy collection of record identifiers that are sorted.
        guard !isCancelled else {
            self.deleteAssetsCompletionBlock?(nil, nil)
            return currentState = .finished
        }
        
        // Define resultant values.
        let resultsLock = DispatchSemaphore(value: 1)
        var deletedAssetIDs: [RFAsset.ID]?
        var operationalError: RFError?
        
        // Create an operation to handle the completion.
        let blockOperation = BlockOperation { [weak self] in
            self?.deleteAssetsCompletionBlock?(deletedAssetIDs, operationalError)
            self?.currentState = .finished
        }
        
        // Filter out the ineligible asset identifiers.
        let assetIDsToDeleteDirectly = shouldDeleteFoldersImmediately ? assetIDs : assetIDs?.lazy.filter { !$0.isFolder }
        
        // Create a request to directly delete records.
        let deleteOperation = RFDeleteAssetsDirectlyOperation(assetIDs: assetIDsToDeleteDirectly)
        deleteOperation.setProperties(basedOn: self)
        
        // Process the results.
        deleteOperation.deleteAssetsDirectlyCompletionBlock = { _deletedAssetIDs, error in
            resultsLock.wait()
            if let _deletedAssetIDs = _deletedAssetIDs {
                if deletedAssetIDs == nil {
                    deletedAssetIDs = _deletedAssetIDs
                } else {
                    deletedAssetIDs?.append(contentsOf: _deletedAssetIDs)
                }
            }
            RFError.update(&operationalError, withPartialError: error, forItemID: deleteOperation.operationID)
            resultsLock.signal()
        }
        
        // Make the block dependant on this operation and begin it.
        blockOperation.addDependency(deleteOperation)
        deleteQueue.addOperation(deleteOperation)
        
        // Filter out the folders, if we are treating them differently.
        if !shouldDeleteFoldersImmediately, let folderAssetIDs = self.assetIDs?.lazy.filter({ $0.isFolder }) {
            // Enumerate the folders.
            for folderAssetID in folderAssetIDs {
                // Create an operation to delete the folder.
                let deleteFolderOperation = RFDeleteFolderOperation(assetID: folderAssetID)
                deleteFolderOperation.setProperties(basedOn: self)
                
                // Handle the completion.
                deleteFolderOperation.deleteFolderCompletionBlock = { deletedAssetID, error in
                    resultsLock.wait()
                    if let deletedAssetID = deletedAssetID {
                        if deletedAssetIDs == nil {
                            deletedAssetIDs = [deletedAssetID]
                        } else {
                            deletedAssetIDs?.append(deletedAssetID)
                        }
                    }
                    RFError.update(&operationalError, withPartialError: error, forItemID: deletedAssetID)
                    resultsLock.signal()
                }
                
                // Make the operation dependant on the original delete operation.
                // The block is dependant on this.
                // Start the operation.
                deleteFolderOperation.addDependency(deleteOperation)
                blockOperation.addDependency(deleteFolderOperation)
                deleteQueue.addOperation(deleteFolderOperation)
            }
        }
        
        // Add the block to the queue, which will be executed when ready.
        deleteQueue.addOperation(blockOperation)
    }
    
    open override func cancel() {
        super.cancel()
    }
}
