//
//  RFRecord.swift
//  RFCore
//
//  Created by David Moore on 7/17/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation
import AWSS3
import AWSDynamoDB

/// An object that represents a record in the relative storage system of RFCore.
open class RFRecord: NSObject {
    
    // MARK: - Types
    
    public typealias FieldKey = String
    public typealias RecordType = String
    
    /// Keys that are required for internal use.
    static let requiredKeys = [InternalFieldKeys.recordType, InternalFieldKeys.recordID]
    
    /// Internal types of records.
    internal struct InternalRecordTypes {
        static let storage = "__Storage"
    }
    
    /// Internal field keys to use for private usage.
    internal struct InternalFieldKeys {
        static let recordType = "RecordType"
        static let recordID = "RecordID"
        static let asset = "__Asset"
    }
    
    /// Keys to set for metadata.
    internal struct MetadataKeys {
        static let modificationDate = "x-amz-meta-modification-date"
        static let lastModified = "Last-Modified"
        static let entityTag = "Etag"
    }
    
    /// An object that uniquely identifies a record in a database.
    @objc(RFRecordID)
    open class ID: NSObject {
        /// The unique name of the record.
        open private(set) var recordName: String
        
        /// A boolean value indicating if the record is a folder.
        open var isFolder: Bool {
            return recordName.last == "/"
        }
        
        /// Creates a new `ID` with `recordName`.
        public init(recordName: String) {
            self.recordName = recordName
            super.init()
        }
        
        /// Returns the hash value.
        open override var hash: Int {
            var hasher = Hasher()
            hasher.combine(recordName)
            
            return hasher.finalize()
        }
        
        /// Returns if the two objects are equal to one another.
        open override func isEqual(_ object: Any?) -> Bool {
            if object is RFRecord.ID {
                return recordName == (object as! RFRecord.ID).recordName
            } else {
                return false
            }
        }
    }
    
    // MARK: - Properties
    
    /// The specific type of this record; used for partitioning availability of the record in a database.
    open private(set) var recordType: RecordType {
        didSet {
            valueStorage[RFRecord.InternalFieldKeys.recordType] = recordType
        }
    }
    
    /// The unique ID of the record.
    open private(set) var recordID: RFRecord.ID {
        didSet {
            valueStorage[RFRecord.InternalFieldKeys.recordID] = recordID.recordName
        }
    }
    
    /// The time when the record was first saved to the server.
    open internal(set) var creationDate: Date?
    
    /// The time when the record was last saved to the server.
    open internal(set) var modificationDate: Date?
    
    /// Unique string attached to a particular set of data stored on the server.
    open internal(set) var entityTag: String?
    
    /// Asset associated with the record; the actual value-based object that backs the receiver.
    open var asset: RFAsset? {
        get {
            return valueStorage[InternalFieldKeys.asset] as? RFAsset
        } set {
            valueStorage[InternalFieldKeys.asset] = newValue
        }
    }
    
    /// Store to maintain record values.
    internal private(set) var valueStorage: RFRecordValueStorage
    
    /// Collection of all keys that are being stored.
    open var allKeys: [FieldKey] {
        return valueStorage.allKeys
    }
    
    /// Collection of field keys that have been changed since the last save.
    open var changedKeys: [FieldKey] {
        return Array(valueStorage.changedKeys)
    }
    
    // MARK: - Initialization
    
    @available(*, unavailable)
    public override init() {
        fatalError()
    }
    
    /// Internal constructor that creates and returns a new record.
    fileprivate init(__recordType recordType: RecordType, __recordID recordID: ID,
                     __valueStorage valueStorage: RFRecordValueStorage = RFRecordValueStorage()) {
        self.valueStorage = valueStorage
        self.recordType = recordType
        self.recordID = recordID
        
        self.valueStorage[RFRecord.InternalFieldKeys.recordType] = recordType
        self.valueStorage[RFRecord.InternalFieldKeys.recordID] = recordID.recordName
    }
    
    /// Creates and returns a new record with the given `recordID`.
    public convenience init(recordID: ID) {
        self.init(__recordType: InternalRecordTypes.storage, __recordID: recordID)
    }
    
    /// Creates and returns a new record with a particular `recordType` and `recordID`.
    public convenience init(recordType: RecordType, recordID: ID = ID(recordName: UUID().uuidString)) {
        self.init(__recordType: recordType, __recordID: recordID)
    }
    
    /// Creates and returns a new record derrived from `object`.
    internal convenience init(object: AWSS3Object) {
        self.init(__recordType: InternalRecordTypes.storage, __recordID: ID(recordName: object.key!))
        self.modificationDate = object.lastModified
        self.entityTag = object.eTag?.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }
    
    /// Creates and returns a new record with an item
    internal convenience init(item: [String: AWSDynamoDBAttributeValue]) {
        let valueStorage = RFRecordValueStorage(item: item)
        let recordType = valueStorage[InternalFieldKeys.recordType] as! String
        let recordID = ID(recordName: valueStorage[InternalFieldKeys.recordID] as! String)
        self.init(__recordType: recordType, __recordID: recordID, __valueStorage: valueStorage)
    }
    
    /// Creates and returns a new record with the asset.
    internal convenience init(asset: RFAsset) {
        self.init(__recordType: InternalRecordTypes.storage, __recordID: RFRecord.ID(recordName: asset.assetID.assetName))
        self.asset = asset
    }
    
    /// Creates and returns a new record with the asset, if it is backed by a value.
    internal convenience init?(asset: RFAsset?) {
        if let asset = asset {
            self.init(asset: asset)
        } else {
            return nil
        }
    }
    
    // MARK: - Accessing Fields
    
    /// Returns the object value stored under the given key.
    open func object(forKey key: FieldKey) -> RFRecordValue? {
        // TODO: Validate key.
        return valueStorage[key]
    }
    
    /// Stores the object value for the given key in a value store.
    open func setObject(_ object: RFRecordValue?, forKey key: FieldKey) {
        // TODO: Validate key.
        // TODO: Validate value.
        valueStorage[key] = object
    }
    
    /// Retrieves or sets a value for a specific key.
    open subscript(key: FieldKey) -> RFRecordValue? {
        get {
            return object(forKey: key)
        } set {
            setObject(newValue, forKey: key)
        }
    }
    
    // MARK: - Hashablility
    
    /// Returns the hash value.
    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(recordID)
        hasher.combine(creationDate)
        hasher.combine(modificationDate)
        hasher.combine(valueStorage)
        hasher.combine(entityTag)
        
        return hasher.finalize()
    }
    
    // MARK: - Equatability
    
    /// Returns if the two objects are equal to one another.
    open override func isEqual(_ object: Any?) -> Bool {
        let rhs = (object as? RFRecord)
        return recordID == rhs?.recordID && creationDate == rhs?.creationDate && modificationDate == rhs?.modificationDate && entityTag == rhs?.entityTag
    }
}

/// A structure that acts as a store for record values.
internal struct RFRecordValueStorage: Hashable {
    
    // MARK: - Properties
    
    /// Underlying map store to contain all of the record values.
    private(set) var map: [String: RFRecordValue]
    
    /// Collection of keys that have been changed after the last write.
    private(set) var changedKeys: Set<String> = []
    
    /// Item that is computed on-call; contains all of the stored record values wrapped in attribute value objects.
    @available(*, deprecated, message: "Use 'databaseItem(with:)' instead.")
    var computedItem: [String: AWSDynamoDBAttributeValue] {
        return map.mapValues { encode($0) }
    }
    
    /// Collection of the keys that are currently being stored.
    var allKeys: [String] {
        return Array(map.keys)
    }

    // MARK: - Initialization
    
    /// Creates and returns a new store with a map derrived from the provided `item`.
    init(item: [String: AWSDynamoDBAttributeValue]) {
        // Initialize the map.
        map = [:]
        
        // Decode the item.
        map = item.mapValues { decode($0) }
    }
    
    /// Creates and returns a new store with an empty map.
    init() {
        map = [:]
    }
    
    // MARK: - Hashable and Equatable Conformance
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(changedKeys)
        hasher.combine(Array(map.keys))
        hasher.combine(map.values.map { $0 as? AnyHashable })
    }
    
    static func ==(lhs: RFRecordValueStorage, rhs: RFRecordValueStorage) -> Bool {
        return lhs.changedKeys == rhs.changedKeys
    }
    
    // MARK: - Accessing Values
    
    /// Registers a particular value in the store.
    ///
    /// - Parameters:
    ///   - value: Record value that will be stored.
    ///   - key: Unique identifier to be associated with the value.
    mutating func setValue(_ value: RFRecordValue?, forKey key: String) {
        map[key] = value
        changedKeys.insert(key)
    }
    
    /// Returns the value, if one exists, associated with `key`.
    func value(forKey key: String) -> RFRecordValue? {
        return map[key]
    }
    
    subscript(key: String) -> RFRecordValue? {
        get {
            return value(forKey: key)
        } set {
            setValue(newValue, forKey: key)
        }
    }
    
    /// Removes a particular key from the `changedKeys` collection.
    mutating func removeChangedKey(_ key: String) -> String? {
        return changedKeys.remove(key)
    }
    
    // MARK: - Database Item Methods
    
    /// 
    internal var databaseItem: [String: AWSDynamoDBAttributeValue] {
        return map.filter { !($0.value is RFAsset) }.mapValues { encode($0) }
    }
    
    /// Creates and returns an item to use with a database.
    ///
    /// - Parameter assetHandler: Closure that submits and asset to be saved asynchronously, taking a return value of a string that identifies its location in the storage container.
    /// - Returns: Dictionary that can be stored in a database.
    internal func databaseItem(with assetHandler: ((RFAsset) -> RFAssetReference)) -> [String: AWSDynamoDBAttributeValue] {
        return map.mapValues { value -> AWSDynamoDBAttributeValue in
            if let asset = value as? RFAsset {
                return encode(assetHandler(asset))
            } else {
                return encode(value)
            }
        }
    }
    
    // MARK: - Coding

    /// Encodes a record value to an `AWSDynamoDBAttributeValue`.
    private func encode(_ value: RFRecordValue) -> AWSDynamoDBAttributeValue {
        let attributeValue = AWSDynamoDBAttributeValue()!
        
        if let value = value as? NSData {
            attributeValue.b = value as Data
        } else if let value = value as? NSArray {
            if let dataArray = value as? [Data] {
                attributeValue.bs = dataArray
            } else if let numberArray = value as? [NSNumber] {
                attributeValue.ns = numberArray.map { $0.stringValue }
            } else if let stringArray = value as? [String] {
                attributeValue.ss = stringArray
            } else if let valueArray = value as? [RFRecordValue] {
                attributeValue.l = valueArray.map { encode($0) }
            }
        } else if let value = value as? Bool {
            attributeValue.boolean = value as NSNumber
        } else if let value = value as? NSNumber {
            attributeValue.n = value.stringValue
        } else if let value = value as? NSString {
            attributeValue.s = value as String
        } else if let valueMap = value as? NSDictionary {
            attributeValue.m = ((valueMap as? [String: Any]) as? [String: RFRecordValue])?.mapValues { encode($0) }
        } else if let assetReference = value as? RFAssetReference {
            attributeValue.s = assetReference.rawValue
        } else if let date = value as? NSDate {
            let dateFormatter = ISO8601DateFormatter()
            attributeValue.s = "__Date:" + dateFormatter.string(from: date as Date)
        } else {
            fatalError("Expected value to be of a compliant type.")
        }
        
        return attributeValue
    }
    
    /// Decodes an `AWSDynamoDBAttributeValue` into a record value.
    private func decode(_ attributeValue: AWSDynamoDBAttributeValue) -> RFRecordValue {
        if let value = attributeValue.b {
            return value as NSData
        } else if let values = attributeValue.bs {
            return values as NSArray
        } else if let value = attributeValue.boolean {
            return value
        } else if let value = attributeValue.n {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            return numberFormatter.number(from: value) ?? NSNumber(value: 0)
        } else if let values = attributeValue.ns {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            return values.map { numberFormatter.number(from: $0) ?? NSNumber(value: 0) } as NSArray
        } else if let value = attributeValue.s {
            if value.hasPrefix(RFAssetReference.prefix) {
                let assetReference = RFAssetReference(rawValue: value)
                return assetReference
            }
            
            return value as NSString
        } else if let values = attributeValue.ss {
            return values as NSArray
        } else if let values = attributeValue.l {
            return values.map { decode($0) } as NSArray
        } else if let valueMap = attributeValue.m {
            return valueMap.mapValues { decode($0) } as NSDictionary
        } else {
            fatalError("Attribute value invalid, decoding failed.")
        }
    }
}
