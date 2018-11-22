//
//  RFAssetReference.swift
//  RFCore
//
//  Created by David Moore on 8/26/18.
//

import Foundation

/// An object that is used to reference a particular asset.
internal class RFAssetReference: RawRepresentable, Hashable, RFRecordValue {
    
    // MARK: - Properties
    
    /// Prefix for an asset reference.
    internal static let prefix = "__Asset:"
    
    /// Type of the raw value.
    internal typealias RawValue = String
    
    /// Raw value of the reference.
    internal let rawValue: String
    
    // MARK: - Computed Values
    
    /// Base string that does not include the prefix.
    private var base: String {
        return String(rawValue[rawValue.range(of: RFAssetReference.prefix)!.upperBound...])
    }
    
    /// Components of the reference, split apart.
    private var components: [String] {
        return base.split(separator: ".").map { String($0) }
    }
    
    /// Asset identifier of the asset itself.
    internal var assetID: RFAsset.ID {
        return RFAsset.ID(assetName: base)
    }
    
    /// Type of the record the asset is associated with.
    internal var parentRecordType: RFRecord.RecordType {
        return components[0]
    }
    
    /// Record identifier of the record the asset is associated with.
    internal var parentRecordID: RFRecord.ID {
        return RFRecord.ID(recordName: components[1])
    }
    
    /// The key with which the asset was stored in the record.
    internal var assetKey: RFRecord.FieldKey {
        return components[2]
    }
    
    // MARK: - Initialization
    
    /// Creates and returns a new reference with a specific raw value.
    internal required init(rawValue: String) {
        precondition(rawValue.hasPrefix(RFAssetReference.prefix) && rawValue.filter { $0 == "." }.count == 2,
                     "Asset reference format validation failed.")
        self.rawValue = rawValue
    }
    
    /// Creates and returns a new reference.
    internal convenience init(assetRecordID: RFRecord.ID) {
        self.init(rawValue: RFAssetReference.prefix + assetRecordID.recordName)
    }
    
    /// Creates and returns a new reference given a few values.
    internal convenience init(recordType: RFRecord.RecordType, recordID: RFRecord.ID, assetKey: RFRecord.FieldKey) {
        self.init(rawValue: "\(RFAssetReference.prefix)\(recordType).\(recordID.recordName).\(assetKey)")
    }
    
    /// Creates and returns a new reference given a few values.
    internal convenience init(record: RFRecord, assetKey: RFRecord.FieldKey) {
        self.init(recordType: record.recordType, recordID: record.recordID, assetKey: assetKey)
    }
    
    // MARK: - Hashing
    
    /// Hash function for an asset reference.
    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
    
    /// Equating function.
    static func ==(lhs: RFAssetReference, rhs: RFAssetReference) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}
