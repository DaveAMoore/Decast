//
//  AnyCodingKey.swift
//  MoreCodable
//
//  Created by Tatsuya Tanaka on 20180211.
//  Copyright © 2018年 tattn. All rights reserved.
//

import Foundation

internal struct AnyCodingKey : CodingKey {
    internal var stringValue: String
    internal var intValue: Int?

    internal init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    internal init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    internal init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }

    internal static let `super` = AnyCodingKey(stringValue: "super")!
}
