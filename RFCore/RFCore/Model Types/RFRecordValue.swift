//
//  RFRecordValue.swift
//  RFCore
//
//  Created by David Moore on 8/19/18.
//

import Foundation

/// Protocol that determines eligible record values. Do not make custom classes conform to `RFRecordValue`.
public protocol RFRecordValue {}

extension String: RFRecordValue {}
extension Dictionary: RFRecordValue where Key == String, Value: RFRecordValue {}
extension Array: RFRecordValue where Element: RFRecordValue {}
extension Date: RFRecordValue {}
extension Data: RFRecordValue {}
extension Bool: RFRecordValue {}
extension Int: RFRecordValue {}
extension Float: RFRecordValue {}
extension Double: RFRecordValue {}

extension NSString: RFRecordValue {}
extension NSArray: RFRecordValue {}
extension NSDictionary: RFRecordValue {}
extension NSNumber: RFRecordValue {}
extension NSDate: RFRecordValue {}
extension NSData: RFRecordValue {}

extension RFAsset: RFRecordValue {}
