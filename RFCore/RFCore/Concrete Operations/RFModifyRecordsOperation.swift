//
//  RFModifyRecordsOperation.swift
//  RFCore
//
//  Created by David Moore on 7/17/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

/// An operation that saves changes to one or more record objects.
open class RFModifyRecordsOperation: RFContainerOperation {

    // MARK: - Properties
    
    /// The records to save to the database.
    open var recordsToSave: [RFRecord]?
    
    /// The IDs of the records to delete permanently from the database.
    open var recordIDsToDelete: [RFRecord.ID]?
    
    /// The block to execute with progress information for an individual record.
    open var perRecordProgressBlock: ((RFRecord, Double) -> Void)?
    
    /// The block to execute when the save results of a single record are known.
    open var perRecordCompletionBlock: ((RFRecord, Error?) -> Void)?
    
    /// The block to execute after the status of all changes is known.
    open var modifyRecordsCompletionBlock: (([RFRecord]?, [RFRecord.ID]?, Error?) -> Void)?
    
    /// Operation queue used to execute modification-related operations.
    internal lazy var modificationQueue: OperationQueue = OperationQueue()
    
    // MARK: - Initialization
    
    /// Initializes and returns an operation object.
    public convenience init(recordsToSave: [RFRecord]?, recordIDsToDelete: [RFRecord.ID]?) {
        self.init()
        self.recordsToSave = recordsToSave
        self.recordIDsToDelete = recordIDsToDelete
    }
    
    /// Initializes and returns an operation object.
    public override init() {
        super.init()
    }
    
    // MARK: - State
    
    open override func start() {
        super.start()
        
        guard !isCancelled else {
            self.modifyRecordsCompletionBlock?(nil, nil, nil)
            return currentState = .finished
        }
        
        // Update the state.
        currentState = .executing
        
        // Declare some state-related variables.
        let resultsLock = DispatchSemaphore(value: 1)
        var savedRecords: [RFRecord]?
        var deletedRecordIDs: [RFRecord.ID]?
        var operationalError: RFError?
        
        // Create a block to finalize the operation.
        let blockOperation = BlockOperation { [weak self] in
            self?.modifyRecordsCompletionBlock?(savedRecords, deletedRecordIDs, operationalError)
            self?.currentState = .finished
        }
        
        if isDatabaseOperation {
            let modificationOperation = RFModifyRecordsDatabaseOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
            modificationOperation.setProperties(basedOn: self)
            
            modificationOperation.modifyRecordsCompletionBlock = { savedRecords, savedRecordIDs, error in
                resultsLock.wait()
                
                RFError.update(&operationalError, withPartialError: error, forItemID: "SavedRecords.DB")
                resultsLock.signal()
            }
            
            blockOperation.addDependency(modificationOperation)
            modificationQueue.addOperation(modificationOperation)
        }
        
        // TODO: Update below for new database model of use.
        
        // Create and configure the save operation.
        let saveOperation = RFSaveAssetsOperation(assets: [])
        saveOperation.setProperties(basedOn: self)
        saveOperation.transferUtility = operationalContainer.transferUtility
        
        // Handle per record progress reporting.
        saveOperation.perAssetProgressBlock = { [weak self] asset, progress in
            self?.perRecordProgressBlock?(RFRecord(asset: asset), progress)
        }
        
        // Deal with per record completion reporting.
        saveOperation.perAssetCompletionBlock = { [weak self] asset, error in
            RFError.update(&operationalError, withPartialError: error, forItemID: asset.assetID)
            self?.perRecordCompletionBlock?(RFRecord(asset: asset), error)
        }
        
        // Handle the return of the saved records.
        saveOperation.saveAssetsCompletionBlock = { savedAssets, error in
            resultsLock.wait()
            savedRecords = savedAssets?.map { RFRecord(asset: $0) }
            RFError.update(&operationalError, withPartialError: error, forItemID: "SavedRecords")
            resultsLock.signal()
        }
        
        // Start the save operation immediately.
        blockOperation.addDependency(saveOperation)
        modificationQueue.addOperation(saveOperation)
        
        // Configure the delete operation, while making it contingent on the save operation.
        let deleteOperation = RFDeleteAssetsOperation(assetIDs: [] /* recordIDsToDelete?.map { RFAsset.ID(assetName: $0.recordName) } */)
        deleteOperation.setProperties(basedOn: self)
        deleteOperation.addDependency(saveOperation)
        
        // Handle the completion of the delete.
        deleteOperation.deleteAssetsCompletionBlock = { deletedAssetIDs, error in
            resultsLock.wait()
            deletedRecordIDs = deletedAssetIDs?.map { RFRecord.ID(recordName: $0.assetName) }
            RFError.update(&operationalError, withPartialError: error, forItemID: "DeletedRecordIDs")
            resultsLock.signal()
        }
        
        // Submit the delete operation to the queue.
        blockOperation.addDependency(deleteOperation)
        modificationQueue.addOperation(deleteOperation)
        
        // Submit the block operation, which will wait until its dependencies are complete.
        modificationQueue.addOperation(blockOperation)
    }
    
    open override func cancel() {
        super.cancel()
        
        modificationQueue.cancelAllOperations()
        currentState = .finished
    }
}
