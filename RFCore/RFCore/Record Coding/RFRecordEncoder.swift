//
//  RFRecordEncoder.swift
//  RemoteKit
//
//  Created by David Moore on 11/21/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

public class RFRecordEncoder: Encoder {
    public var codingPath: [CodingKey] = []
    public var userInfo: [CodingUserInfoKey : Any] = [:]
    public var record: RFRecord
    private var storage = Storage()
    
    public init(for record: RFRecord) {
        self.record = record
    }
    
    public func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        return KeyedEncodingContainer(KeyedContainer<Key>(encoder: self, codingPath: codingPath))
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        return UnkeyedContanier(encoder: self, codingPath: codingPath)
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        return SingleValueContanier(encoder: self, codingPath: codingPath)
    }
    
    private func box<T>(_ value: T) throws -> Any where T: Encodable {
        if value is [Any] || value is RFRecordValue {
            try value.encode(to: self)
            return storage.popContainer()
        } else {
            let dictionaryEncoder = DictionaryEncoder()
            let dictionary = try dictionaryEncoder.encode(value)
            
            return dictionary
        }
    }
}

extension RFRecordEncoder {
    public func encode<T: Encodable>(_ value: T) throws {
        do {
            try value.encode(to: self)
        } catch {
            let context = EncodingError.Context(codingPath: [],
                                                debugDescription: "Top level \(T.self) encoding failed.", underlyingError: error)
            throw EncodingError.invalidValue(value, context)
        }
    }
}

extension RFRecordEncoder {
    private class KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        private var encoder: RFRecordEncoder
        private(set) var codingPath: [CodingKey]
        private var storage: Storage
        
        init(encoder: RFRecordEncoder, codingPath: [CodingKey]) {
            self.encoder = encoder
            self.codingPath = codingPath
            self.storage = encoder.storage
            
            storage.push(container: encoder.record)
        }
        
        deinit {
            guard let record = storage.popContainer() as? RFRecord else {
                assertionFailure(); return
            }
            storage.push(container: record)
        }
        
        private func set(_ value: Any, forKey key: String) throws {
            guard let record = storage.popContainer() as? RFRecord else { return assertionFailure() }
            if let recordValue = value as? RFRecordValue {
                record[key] = recordValue
            } else if let recordValue = value as? [[String: RFRecordValue]] {
                record[key] = recordValue as RFRecordValue
            } else {
                let context = EncodingError.Context(codingPath: [], debugDescription: "Expected value of type 'RFRecordValue'.")
                throw EncodingError.invalidValue(value, context)
            }
            
            storage.push(container: record)
        }
        
        func encodeNil(forKey key: Key) throws {}
        func encode(_ value: Bool, forKey key: Key) throws { try set(value, forKey: key.stringValue) }
        func encode(_ value: Int, forKey key: Key) throws { try set(value, forKey: key.stringValue) }
        func encode(_ value: Int8, forKey key: Key) throws { try set(value, forKey: key.stringValue) }
        func encode(_ value: Int16, forKey key: Key) throws { try set(value, forKey: key.stringValue) }
        func encode(_ value: Int32, forKey key: Key) throws { try set(value, forKey: key.stringValue) }
        func encode(_ value: Int64, forKey key: Key) throws { try set(value, forKey: key.stringValue) }
        func encode(_ value: UInt, forKey key: Key) throws { try set(value, forKey: key.stringValue) }
        func encode(_ value: UInt8, forKey key: Key) throws { try set(value, forKey: key.stringValue) }
        func encode(_ value: UInt16, forKey key: Key) throws { try set(value, forKey: key.stringValue) }
        func encode(_ value: UInt32, forKey key: Key) throws { try set(value, forKey: key.stringValue) }
        func encode(_ value: UInt64, forKey key: Key) throws { try set(value, forKey: key.stringValue) }
        func encode(_ value: Float, forKey key: Key) throws { try set(value, forKey: key.stringValue) }
        func encode(_ value: Double, forKey key: Key) throws { try set(value, forKey: key.stringValue) }
        func encode(_ value: String, forKey key: Key) throws { try set(value, forKey: key.stringValue) }
        func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            encoder.codingPath.append(key)
            defer { encoder.codingPath.removeLast() }
            try set(try encoder.box(value), forKey: key.stringValue)
        }
        
        func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
            codingPath.append(key)
            defer { codingPath.removeLast() }
            return KeyedEncodingContainer(KeyedContainer<NestedKey>(encoder: encoder, codingPath: codingPath))
        }
        
        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            codingPath.append(key)
            defer { codingPath.removeLast() }
            return UnkeyedContanier(encoder: encoder, codingPath: codingPath)
        }
        
        func superEncoder() -> Encoder {
            return encoder
        }
        
        func superEncoder(forKey key: Key) -> Encoder {
            return encoder
        }
    }
    
    private class UnkeyedContanier: UnkeyedEncodingContainer {
        var encoder: RFRecordEncoder
        private(set) var codingPath: [CodingKey]
        private var storage: Storage
        var count: Int { return storage.count }
        
        init(encoder: RFRecordEncoder, codingPath: [CodingKey]) {
            self.encoder = encoder
            self.codingPath = codingPath
            self.storage = encoder.storage
            
            storage.push(container: [] as [Any])
        }
        
        deinit {
            guard let array = storage.popContainer() as? [Any] else {
                assertionFailure(); return
            }
            storage.push(container: array)
        }
        
        private func push(_ value: Any) {
            guard var array = storage.popContainer() as? [Any] else { assertionFailure(); return }
            array.append(value)
            storage.push(container: array)
        }
        
        func encodeNil() throws {}
        func encode(_ value: Bool) throws {}
        func encode(_ value: Int) throws { push(try encoder.box(value)) }
        func encode(_ value: Int8) throws { push(try encoder.box(value)) }
        func encode(_ value: Int16) throws { push(try encoder.box(value)) }
        func encode(_ value: Int32) throws { push(try encoder.box(value)) }
        func encode(_ value: Int64) throws { push(try encoder.box(value)) }
        func encode(_ value: UInt) throws { push(try encoder.box(value)) }
        func encode(_ value: UInt8) throws { push(try encoder.box(value)) }
        func encode(_ value: UInt16) throws { push(try encoder.box(value)) }
        func encode(_ value: UInt32) throws { push(try encoder.box(value)) }
        func encode(_ value: UInt64) throws { push(try encoder.box(value)) }
        func encode(_ value: Float) throws { push(try encoder.box(value)) }
        func encode(_ value: Double) throws { push(try encoder.box(value)) }
        func encode(_ value: String) throws { push(try encoder.box(value)) }
        func encode<T: Encodable>(_ value: T) throws {
            encoder.codingPath.append(AnyCodingKey(index: count))
            defer { encoder.codingPath.removeLast() }
            push(try encoder.box(value))
        }
        
        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            codingPath.append(AnyCodingKey(index: count))
            defer { codingPath.removeLast() }
            return KeyedEncodingContainer(KeyedContainer<NestedKey>(encoder: encoder, codingPath: codingPath))
        }
        
        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            codingPath.append(AnyCodingKey(index: count))
            defer { codingPath.removeLast() }
            return UnkeyedContanier(encoder: encoder, codingPath: codingPath)
            
        }
        
        func superEncoder() -> Encoder {
            return encoder
        }
    }
    
    private class SingleValueContanier: SingleValueEncodingContainer {
        var encoder: RFRecordEncoder
        private(set) var codingPath: [CodingKey]
        private var storage: Storage
        var count: Int { return storage.count }
        
        init(encoder: RFRecordEncoder, codingPath: [CodingKey]) {
            self.encoder = encoder
            self.codingPath = codingPath
            self.storage = encoder.storage
        }
        
        private func push(_ value: Any) {
            guard var array = storage.popContainer() as? [Any] else { assertionFailure(); return }
            array.append(value)
            storage.push(container: array)
        }
        
        func encodeNil() throws {}
        func encode(_ value: Bool) throws { storage.push(container: value) }
        func encode(_ value: Int) throws { storage.push(container: value) }
        func encode(_ value: Int8) throws { storage.push(container: value) }
        func encode(_ value: Int16) throws { storage.push(container: value) }
        func encode(_ value: Int32) throws { storage.push(container: value) }
        func encode(_ value: Int64) throws { storage.push(container: value) }
        func encode(_ value: UInt) throws { storage.push(container: value) }
        func encode(_ value: UInt8) throws { storage.push(container: value) }
        func encode(_ value: UInt16) throws { storage.push(container: value) }
        func encode(_ value: UInt32) throws { storage.push(container: value) }
        func encode(_ value: UInt64) throws { storage.push(container: value) }
        func encode(_ value: Float) throws { storage.push(container: value) }
        func encode(_ value: Double) throws { storage.push(container: value) }
        func encode(_ value: String) throws { storage.push(container: value) }
        func encode<T: Encodable>(_ value: T) throws { storage.push(container: try encoder.box(value)) }
    }
}
