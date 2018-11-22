//
//  Utilities.swift
//  RFCore
//
//  Created by David Moore on 7/21/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

extension QualityOfService {
    /// Translated QoS class from `QualityOfService` to `DispatchQoS.QoSClass`.
    internal var qosClass: DispatchQoS.QoSClass {
        switch self {
        case .background:
            return .background
        case .default:
            return .default
        case .userInitiated:
            return .userInitiated
        case .userInteractive:
            return .userInteractive
        case .utility:
            return .utility
        }
    }
}

extension HTTPURLResponse {
    /// Entity tag stored in the response header fields.
    internal var entityTag: String? {
        let tag = allHeaderFields[RFRecord.MetadataKeys.entityTag] as? String
        return tag?.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }
}

/// Creates and returns a projection expression for a particular collection of desired keys.
internal func projectionExpression(forDesiredKeys desiredKeys: [String]?) -> String? {
    // Unwrap the keys.
    guard let desiredKeys = desiredKeys else { return nil }
    
    // Generate the projection expression.
    return (desiredKeys + RFRecord.requiredKeys).reduce("") { expression, desiredKey -> String in
        if expression.isEmpty {
            return desiredKey
        } else {
            return expression + ",\(desiredKey)"
        }
    }
}
