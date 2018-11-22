//
//  RFDeleteFolderOperation.swift
//  RFCore
//
//  Created by David Moore on 7/31/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

/// An operation that deletes a specific folder and all of its contained assets.
internal class RFDeleteFolderOperation: RFContainerOperation {

    // MARK: - Properties
    
    /// The ID of the folder asset to delete permanently from the database.
    open var assetID: RFAsset.ID?
    
    /// The block to execute after the status of all changes is known.
    open var deleteFolderCompletionBlock: ((RFAsset.ID?, Error?) -> Void)?
    
    /// Queue for internal operations.
    internal var operationQueue = OperationQueue()
    
    // MARK: - Initialization
    
    /// Initializes and returns an operation object.
    public convenience init(assetID: RFAsset.ID?) {
        self.init()
        self.assetID = assetID
    }
    
    /// Initializes and returns an operation object.
    public override init() {
        super.init()
    }
    
    // MARK: - State
    
    open override func start() {
        super.start()
        
        guard !isCancelled, let assetID = assetID else {
            deleteFolderCompletionBlock?(nil, nil)
            return currentState = .finished
        }
        
        var operationalError: RFError?
        
        func perform(_ query: RFQuery?, orResumeWith cursor: RFQueryOperation.Cursor?) {
            // Create a query operation to execute the query, or at least follow the cursor.
            let queryOperation = RFQueryOperation()
            queryOperation.setProperties(basedOn: self)
            queryOperation.query = query
            queryOperation.cursor = cursor
            
            // Handle the completion.
            queryOperation.queryCompletionBlock = { [weak self] recordsToDelete, cursor, error in
                guard let strongSelf = self else { return }
                
                // Map the asset IDs.
                let assetIDsToDelete = recordsToDelete?.compactMap { $0.asset?.assetID }
                
                // Create an operation that will delete all queried records.
                let deleteOperation = RFDeleteAssetsOperation(assetIDs: assetIDsToDelete)
                deleteOperation.setProperties(basedOn: strongSelf)
                deleteOperation.shouldDeleteFoldersImmediately = cursor == nil
                
                // Handle the completion of the delete operation.
                deleteOperation.deleteAssetsCompletionBlock = { deletedRecordIDs, error in
                    // Update the error.
                    RFError.update(&operationalError, withPartialError: error, forItemID: deleteOperation.assetIDs)
                    
                    // Attempt to follow the cursor if possible.
                    if let cursor = cursor {
                        perform(nil, orResumeWith: cursor)
                    } else {
                        // Call the final completion.
                        strongSelf.deleteFolderCompletionBlock?(assetID, operationalError)
                        strongSelf.currentState = .finished
                    }
                }
                
                // Remove the record identifier if it was included as a part of the query.
                if cursor != nil, let duplicateIndex = deleteOperation.assetIDs?.index(of: assetID) {
                    deleteOperation.assetIDs?.remove(at: duplicateIndex)
                }
                
                // Begin executing the delete operation.
                strongSelf.operationQueue.addOperation(deleteOperation)
            }
            
            // Start executing the query.
            operationQueue.addOperation(queryOperation)
        }
        
        // Update the state.
        currentState = .executing
        
        // Execute the initial query.
        let query = RFQuery(prefix: assetID.assetName)
        perform(query, orResumeWith: nil)
    }
    
    open override func cancel() {
        super.cancel()
    }
}
