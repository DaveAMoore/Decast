//
//  RFModifyRecordsDatabaseOperation.swift
//  RFCore
//
//  Created by David Moore on 8/28/18.
//

import Foundation
import AWSDynamoDB

/// An operation that saves changes to one or more record objects.
open class RFModifyRecordsDatabaseOperation: RFContainerOperation {
    
    // MARK: - Properties
    
    /// The records to save to the database.
    open var recordsToSave: [RFRecord]?
    
    /// The IDs of the records to delete permanently from the database.
    open var recordIDsToDelete: [RFRecord.ID]?
    
    /// The block to execute after the status of all changes is known.
    open var modifyRecordsCompletionBlock: (([RFRecord]?, [RFRecord.ID]?, Error?) -> Void)?
    
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
        
        guard !isCancelled, let databaseID = operationalContainer.databaseID else {
            self.modifyRecordsCompletionBlock?(nil, nil, nil)
            return currentState = .finished
        }
        
        // Map each collection in order to create requests for each operation.
        let saveRequests = recordsToSave?
            .map { AWSDynamoDBPutRequest(item: $0.valueStorage.databaseItem) }
            .map { AWSDynamoDBWriteRequest(putRequest: $0) }
        let deleteRequests = recordIDsToDelete?
            .map { AWSDynamoDBDeleteRequest(key: [RFRecord.InternalFieldKeys.recordID: AWSDynamoDBAttributeValue(string: $0.recordName)]) }
            .map { AWSDynamoDBWriteRequest(deleteRequest: $0) }
        
        // Combine the requests in one contiguous array.
        let contiguousRequests = (saveRequests ?? []) + (deleteRequests ?? [])
        
        // Ensure there are indeed requests.
        guard !contiguousRequests.isEmpty else {
            self.modifyRecordsCompletionBlock?(nil, nil, nil)
            return currentState = .finished
        }
        
        // Create a modification request
        let modificationRequest = AWSDynamoDBBatchWriteItemInput()!
        modificationRequest.requestItems = [databaseID: contiguousRequests]
        
        // Begin writing items in batch.
        let modificationTask = operationalContainer.databaseService.batchWriteItem(modificationRequest)
        
        // Update the state.
        currentState = .executing
        
        // Handle the task's completion.
        modificationTask.continueWith { [weak self] task -> Any? in
            guard let strongSelf = self else { return nil }
            
            defer {
                strongSelf.currentState = .finished
            }
            
            // Unwrap the result.
            guard let _ = task.result else {
                strongSelf.modifyRecordsCompletionBlock?(nil, nil, task.error)
                return nil
            }
            
            // Call completion.
            strongSelf.modifyRecordsCompletionBlock?(strongSelf.recordsToSave, strongSelf.recordIDsToDelete, nil)
            
            return nil
        }
    }
    
    open override func cancel() {
        super.cancel()
    }
}
