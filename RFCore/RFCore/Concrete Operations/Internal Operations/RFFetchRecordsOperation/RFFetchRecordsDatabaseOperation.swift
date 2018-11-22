//
//  RFFetchRecordsDatabaseOperation.swift
//  RFCore
//
//  Created by David Moore on 8/26/18.
//

import Foundation
import AWSDynamoDB

internal class RFFetchRecordsDatabaseOperation: RFContainerOperation {

    // MARK: - Properties
    
    /// The array of IDs corresponding to the records to fetch.
    open var recordIDs: [RFRecord.ID]?
    
    /// The fields to retrieve for the requested records.
    open var desiredKeys: [String]?
    
    /// The block to execute with progress information for individual records.
    open var perRecordProgressBlock: ((RFRecord.ID, Double) -> Void)?
    
    /// The block to execute when the results of a single record are available.
    open var perRecordCompletionBlock: ((RFRecord?, RFRecord.ID?, Error?) -> Void)?
    
    /// The block to execute after all records are fetched or have received appropriate errors.
    open var fetchRecordsCompletionBlock: (([RFRecord.ID: RFRecord]?, Error?) -> Void)?
    
    /// Queue to use for fetching.
    private var fetchQueue = OperationQueue()
    
    // MARK: - Initialization
    
    /// Initializes and returns an operation object configured to fetch the records with the specified IDs.
    public convenience init(recordIDs: [RFRecord.ID]) {
        self.init()
        self.recordIDs = recordIDs
    }
    
    public override init() {
        super.init()
    }
    
    // MARK: - State
    
    open override func start() {
        super.start()
        
        guard !isCancelled, let databaseID = operationalContainer.databaseID, let recordIDs = recordIDs else {
            self.fetchRecordsCompletionBlock?(nil, nil)
            return currentState = .finished
        }
        
        // Create an object that contains the keys we must fetch.
        let requestItems = AWSDynamoDBKeysAndAttributes()!
        requestItems.keys = recordIDs.map { [RFRecord.InternalFieldKeys.recordID: AWSDynamoDBAttributeValue(string: $0.recordName)] }
        requestItems.projectionExpression = projectionExpression(forDesiredKeys: desiredKeys)
        
        // Configure a fetch request based on the request items.
        let fetchRequest = AWSDynamoDBBatchGetItemInput()!
        fetchRequest.requestItems = [databaseID: requestItems]
        
        let fetchTask = operationalContainer.databaseService.batchGetItem(fetchRequest)
        
        // Update the state.
        currentState = .executing
        
        // Assign a completion block.
        fetchTask.continueWith { [weak self] task -> Any? in
            guard let strongSelf = self else { return nil }
            
            // Unwrap the result.
            // Map the responses to create records.
            guard let result = task.result, let records = result.responses?[databaseID]?.map({ RFRecord(item: $0) }) else {
                self?.fetchRecordsCompletionBlock?(nil, task.error)
                self?.currentState = .finished
                return nil
            }
            
            // Zip the records with record IDs.
            let recordsByRecordID = Dictionary(uniqueKeysWithValues: zip(records.map { $0.recordID }, records))
            
            // Call completion.
            strongSelf.fetchRecordsCompletionBlock?(recordsByRecordID, nil)
            strongSelf.currentState = .finished
            
            /*
            // Map the asset references.
            let assetReferences = Array(records.map { $0.valueStorage.map.values.lazy.compactMap { $0 as? RFAssetReference }}.joined())
            
            // Configure an operation to fetch referenced assets.
            let fetchOperation = RFFetchAssetsOperation(assetIDs: assetReferences.map { $0.assetID })
            fetchOperation.setProperties(basedOn: strongSelf)
            
            // Relay the progress information back.
            fetchOperation.perAssetProgressBlock = { [weak self] assetRecordID, progress in
                let assetReference = RFAssetReference(assetRecordID: assetRecordID)
                self?.perRecordProgressBlock?(assetReference.parentRecordID, progress)
            }
            
            // Handle each specific asset fetch.
            fetchOperation.perAssetCompletionBlock = { [weak self] fetchedAsset, assetRecordID, error in
                if let assetRecordID = assetRecordID {
                    // Retrieve the record using the asset reference.
                    let assetReference = RFAssetReference(assetRecordID: assetRecordID)
                    let record = recordsByRecordID[assetReference.parentRecordID]
                    
                    // Set the asset under the correct key.
                    record?[assetReference.assetKey] = fetchedAsset
                    
                    // Call completion for this record.
                    self?.perRecordCompletionBlock?(record, assetReference.parentRecordID, error)
                } else {
                    self?.perRecordCompletionBlock?(nil, nil, error)
                }
            }
            
            // Handle the completion.
            fetchOperation.fetchAssetsCompletionBlock = { [weak self] _, error in
                self?.fetchRecordsCompletionBlock?(recordsByRecordID, error)
                self?.currentState = .finished
            }
            
            // Resume the fetch operation.
            strongSelf.fetchQueue.addOperation(fetchOperation)*/
            
            return nil
        }
    }
    
    open override func cancel() {
        super.cancel()
    }
}
