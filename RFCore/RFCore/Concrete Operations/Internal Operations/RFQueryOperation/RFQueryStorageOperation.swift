//
//  RFQueryStorageOperation.swift
//  RFCore
//
//  Created by David Moore on 8/20/18.
//

import Foundation
import AWSS3

/// An operation used to execute queries against a container.
internal class RFQueryStorageOperation: RFContainerOperation {
    
    // MARK: - Properties
    
    /// The query to use for the search.
    open var query: RFQuery?
    
    /// The data cursor to use for continuing the search.
    open var cursor: RFQueryOperation.Cursor?
    
    /// The maximum number of records to return at one time.
    open var resultsLimit = RFQueryOperation.maximumResults
    
    /// The block to execute with the search results.
    open var queryCompletionBlock: (([RFRecord]?, RFQueryOperation.Cursor?, Error?) -> Void)?
    
    // MARK: - Initialization
    
    /// Initializes and returns an operation object configured to search for records.
    public convenience init(query: RFQuery) {
        self.init()
        self.query = query
    }
    
    /// Initializes and returns an operation object that returns more results from a previous search.
    public convenience init(cursor: RFQueryOperation.Cursor) {
        self.init()
        self.cursor = cursor
    }
    
    public override init() {
        super.init()
    }
    
    // MARK: - State
    
    open override func start() {
        super.start()
        
        guard !isCancelled else {
            self.queryCompletionBlock?(nil, nil, nil)
            return currentState = .finished
        }
        
        // Configure a query request with the provided parameters.
        let queryRequest = AWSS3ListObjectsV2Request()!
        queryRequest.bucket = operationalContainer.containerID
        queryRequest.prefix = query?.prefix
        queryRequest.delimiter = query?.delimiter
        queryRequest.maxKeys = NSNumber(value: resultsLimit)
        queryRequest.startAfter = query?.startAfterRecordID?.recordName
        queryRequest.continuationToken = cursor?.continuationToken
        
        // Start performing the task.
        let queryTask = operationalContainer.storageService.listObjectsV2(queryRequest)
        
        // Update the state.
        currentState = .executing
        
        // Assign a continuation block.
        queryTask.continueWith { [weak self] task -> Any? in
            guard let strongSelf = self else { return nil }
            
            defer {
                strongSelf.currentState = .finished
            }
            
            // Unwrap the result.
            guard let result = task.result else {
                strongSelf.queryCompletionBlock?(nil, nil, task.error)
                return nil
            }
            
            // O(n) map of the results to records.
            let records = result.contents?.map { RFRecord(object: $0) }
            
            // Invoke the final query completion block.
            strongSelf.queryCompletionBlock?(records, RFQueryOperation.Cursor(output: result), nil)
            
            return nil
        }
    }
    
    open override func cancel() {
        super.cancel()
    }
}
