//
//  RFQuery.swift
//  RFCore
//
//  Created by David Moore on 7/17/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

/// A query that describes the criteria to apply when searching for records in a container.
open class RFQuery: NSObject {
    
    // MARK: - Properties
    
    /// Type of record the query is targeted towards.
    open private(set) var recordType: RFRecord.RecordType

    /// Predicate used to filter the results that are returned by the query.
    open private(set) var predicate: NSPredicate
    
    /// Boolean value indicating if the query was setup for storage.
    internal private(set) var isStorageQuery: Bool = false
    
    /// All queried records must have their identifiers prefixed by this string.
    open private(set) var prefix: String?
    
    /// Used to group records together.
    open private(set) var delimiter: String?
    
    /// Queries objects after a particular record identifier.
    open private(set) var startAfterRecordID: RFRecord.ID?
    
    // MARK: - Initialization
    
    @available(*, unavailable)
    public override init() {
        fatalError()
    }
    
    /// Returns a query with the provided parameters.
    public init(prefix: String? = nil, delimiter: String? = nil, startAfterRecordID: RFRecord.ID? = nil) {
        self.recordType = RFRecord.InternalRecordTypes.storage
        self.predicate = NSPredicate(value: false)
        self.isStorageQuery = true
        self.prefix = prefix
        self.delimiter = delimiter
        self.startAfterRecordID = startAfterRecordID
    }
    
    /// Creates and returns a query with the provided parameters.
    public init(recordType: RFRecord.RecordType, predicate: NSPredicate) {
        self.recordType = recordType
        self.predicate = predicate
    }
    
    /// Returns a copied query.
    open override func copy() -> Any {
        let copy = RFQuery(recordType: recordType, predicate: predicate)
        copy.isStorageQuery = isStorageQuery
        copy.prefix = prefix
        copy.delimiter = delimiter
        copy.startAfterRecordID = startAfterRecordID
        
        return copy
    }
    
    // MARK: - Equatability
    
    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(recordType)
        hasher.combine(predicate)
        hasher.combine(isStorageQuery)
        hasher.combine(prefix)
        hasher.combine(delimiter)
        hasher.combine(startAfterRecordID)
        
        return hasher.finalize()
    }
    
    /// Returns if the two objects are equal to one another.
    open override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? RFQuery else { return false }
        return recordType == rhs.recordType && prefix == rhs.prefix && delimiter == rhs.delimiter && startAfterRecordID == rhs.startAfterRecordID
    }
}
