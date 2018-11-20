//
//  Utilities.swift
//  Decast
//
//  Created by David Moore on 11/20/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

/// Produces a `String` value for a given type.
///
/// - Parameter type: Type for which a name will be generated for.
/// - Returns: `String` value of the type's given name.
public func name<T>(of type: T) -> String {
    return String(describing: type)
}
