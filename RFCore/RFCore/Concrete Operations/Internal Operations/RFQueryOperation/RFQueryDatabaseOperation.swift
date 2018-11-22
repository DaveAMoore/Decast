//
//  RFQueryDatabaseOperation.swift
//  RFCore
//
//  Created by David Moore on 8/20/18.
//

import Foundation
import AWSDynamoDB

/// An operation used to query records from a database-backed container.
internal class RFQueryDatabaseOperation: RFContainerOperation {
    
    // MARK: - Properties
    
    /// The query to use for the search.
    internal var query: RFQuery?
    
    /// The data cursor to use for continuing the search.
    internal var cursor: RFQueryOperation.Cursor?
    
    /// The maximum number of records to return at one time.
    internal var resultsLimit = RFQueryOperation.maximumResults
    
    /// The fields to retrieve for the requested records.
    internal var desiredKeys: [RFRecord.FieldKey]?
    
    /// The block to execute with the search results.
    internal var queryCompletionBlock: (([RFRecord]?, RFQueryOperation.Cursor?, Error?) -> Void)?
    
    // MARK: - Initialization
    
    /// Initializes and returns an operation object configured to search for records.
    internal convenience init(query: RFQuery) {
        self.init()
        self.query = query
    }
    
    /// Initializes and returns an operation object that returns more results from a previous search.
    internal convenience init(cursor: RFQueryOperation.Cursor) {
        self.init()
        self.cursor = cursor
    }
    
    internal override init() {
        super.init()
    }
    
    // MARK: - State
    
    internal override func start() {
        super.start()
        
        guard let databaseID = operationalContainer.databaseID, let query = query ?? cursor?.query, !isCancelled else {
            self.queryCompletionBlock?(nil, nil, nil)
            return currentState = .finished
        }
        
        // Construct a key condition expression.
        let keyConditionExpression = "\(RFRecord.InternalFieldKeys.recordType) = :\(RFRecord.InternalFieldKeys.recordType)"
        
        // Configure a query request with the provided parameters.
        let queryRequest = AWSDynamoDBQueryInput()!
        queryRequest.tableName = databaseID
        queryRequest.exclusiveStartKey = cursor?.lastEvaluatedKey
        queryRequest.keyConditionExpression = keyConditionExpression
        queryRequest.indexName = "RecordType-index"
        
        // Generate the projection expression.
        queryRequest.projectionExpression = projectionExpression(forDesiredKeys: desiredKeys)
        
        // Provide attribute values for the key condition expression.
        queryRequest.expressionAttributeValues = [":\(RFRecord.InternalFieldKeys.recordType)": AWSDynamoDBAttributeValue(string: query.recordType)]
        
        // Start the query.
        let queryTask = operationalContainer.databaseService.query(queryRequest)
        
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
            
            // O(n) map the results to records.
            let records = result.items?.map { RFRecord(item: $0) }.filter { query.predicate.evaluate(with: $0.valueStorage.map) }
            
            // Invoke the final query completion block.
            strongSelf.queryCompletionBlock?(records, RFQueryOperation.Cursor(query: query, output: result), nil)
            
            return nil
        }
    }
    
    internal override func cancel() {
        super.cancel()
    }
}
