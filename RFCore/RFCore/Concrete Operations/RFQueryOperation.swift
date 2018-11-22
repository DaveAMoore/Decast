//
//  RFQueryOperation.swift
//  Resolution Files
//
//  Created by David Moore on 7/16/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation
import AWSS3
import AWSDynamoDB

/// An operation used to execute queries against a container.
open class RFQueryOperation: RFContainerOperation {
    
    // MARK: - Cursor
    
    /// An opaque object that marks the stopping point for a query and the starting point for retrieving the remaining results.
    @objc(RFQueryCursor) open class Cursor: NSObject, NSSecureCoding {
        /// Supports secure coding.
        public static var supportsSecureCoding: Bool {
            return true
        }
        
        /// Token to continue the query from where it left off; used for query pagination.
        @objc internal var continuationToken: String?
        
        /// Query to use when using `lastEvaluatedKey`.
        @objc internal var query: RFQuery?
        
        /// Key to use to continue the query from where it left off; used for query pagination.
        @objc internal var lastEvaluatedKey: [String: AWSDynamoDBAttributeValue]?
        
        /// Creates and returns a new cursor with a particular continuation token.
        internal init(continuationToken: String) {
            self.continuationToken = continuationToken
            super.init()
        }
        
        /// Creates and returns a new cursor with a particular continuation token.
        internal init(query: RFQuery, lastEvaluatedKey: [String: AWSDynamoDBAttributeValue]) {
            self.query = query.copy() as? RFQuery
            self.lastEvaluatedKey = lastEvaluatedKey
        }
        
        /// Creates and returns a cursor with a continuation token derrived from a list output.
        internal convenience init?(output: AWSS3ListObjectsV2Output) {
            if let continuationToken = output.nextContinuationToken {
                self.init(continuationToken: continuationToken)
            } else {
                return nil
            }
        }
        
        /// Creates and returns a cursor with a last evaluated key derrived from the query output.
        internal convenience init?(query: RFQuery, output: AWSDynamoDBQueryOutput) {
            if let lastEvaluatedKey = output.lastEvaluatedKey {
                self.init(query: query, lastEvaluatedKey: lastEvaluatedKey)
            } else {
                return nil
            }
        }
        
        /// Creates and returns a cursor with a last evaluated key derrived from the query output.
        internal convenience init?(query: RFQuery, output: AWSDynamoDBScanOutput) {
            if let lastEvaluatedKey = output.lastEvaluatedKey {
                self.init(query: query, lastEvaluatedKey: lastEvaluatedKey)
            } else {
                return nil
            }
        }
        
        /// Decodes the object using secure decoding.
        public required init?(coder aDecoder: NSCoder) {
            if let continuationToken = aDecoder.decodeObject(of: NSString.self, forKey: #keyPath(Cursor.continuationToken)) {
                self.continuationToken = continuationToken as String
                super.init()
            } else {
                aDecoder.failWithError(CocoaError.error(.coderValueNotFound))
                return nil
            }
        }
        
        /// Encodes the cursor using secure coding.
        open func encode(with aCoder: NSCoder) {
            aCoder.encode(continuationToken as NSString?, forKey: #keyPath(Cursor.continuationToken))
            aCoder.encode(lastEvaluatedKey as NSDictionary?, forKey: #keyPath(Cursor.lastEvaluatedKey))
        }
    }
    
    // MARK: - Constants
    
    /// A placeholder value representing the maximum number of results to retrieve.
    public static let maximumResults: Int = 1000

    // MARK: - Properties
    
    /// The query to use for the search.
    open var query: RFQuery?
    
    /// The data cursor to use for continuing the search.
    open var cursor: Cursor?
    
    /// The maximum number of records to return at one time.
    open var resultsLimit = RFQueryOperation.maximumResults
    
    /// The fields to retrieve for the requested records.
    open var desiredKeys: [RFRecord.FieldKey]?
    
    /// The block to execute with the search results.
    open var queryCompletionBlock: (([RFRecord]?, Cursor?, Error?) -> Void)?
    
    /// Queue for internal query operations.
    internal var queryQueue = OperationQueue()
    
    // MARK: - Initialization
    
    /// Initializes and returns an operation object configured to search for records.
    public convenience init(query: RFQuery) {
        self.init()
        self.query = query
    }
    
    /// Initializes and returns an operation object that returns more results from a previous search.
    public convenience init(cursor: Cursor) {
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
        
        // Create a completion block to handle the completion.
        let completionBlock: (([RFRecord]?, Cursor?, Error?) -> Void) = { [weak self] records, cursor, error in
            self?.queryCompletionBlock?(records, cursor, error)
            self?.currentState = .finished
        }
        
        // Create a database query if we are eligible.
        if isDatabaseOperation {
            let databaseOperation = RFQueryDatabaseOperation()
            databaseOperation.setProperties(basedOn: self)
            databaseOperation.query = query
            databaseOperation.cursor = cursor
            databaseOperation.resultsLimit = resultsLimit
            databaseOperation.queryCompletionBlock = completionBlock
            
            currentState = .executing
            queryQueue.addOperation(databaseOperation)
        } else {
            let storageOperation = RFQueryStorageOperation()
            storageOperation.setProperties(basedOn: self)
            storageOperation.query = query
            storageOperation.cursor = cursor
            storageOperation.resultsLimit = resultsLimit
            storageOperation.queryCompletionBlock = completionBlock
            
            currentState = .executing
            queryQueue.addOperation(storageOperation)
        }
    }
    
    open override func cancel() {
        super.cancel()
    }
}
