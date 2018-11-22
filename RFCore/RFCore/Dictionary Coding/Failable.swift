//
//  Failable.swift
//  MoreCodable
//
//  Created by Tatsuya Tanaka on 20180219.
//  Copyright © 2018年 tattn. All rights reserved.
//

import Foundation

internal struct Failable<Wrapped: Codable>: Codable {
    internal let value: Wrapped?

    internal init(from decoder: Decoder) throws {
        do {
            let container = try decoder.singleValueContainer()
            value = try container.decode(Wrapped.self)
        } catch {
            value = nil
        }
    }

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let value = self.value {
            try container.encode(value)
        } else {
            try container.encodeNil()
        }
    }
}
