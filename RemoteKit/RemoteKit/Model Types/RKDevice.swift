//
//  RKDevice.swift
//  RemoteKit
//
//  Created by David Moore on 11/13/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

public struct RKDevice: Codable, Equatable {
    
    // MARK: - Properties
    
    /// Serial number of an `RKDevice`.
    public let serialNumber: String
    
    // MARK: - Initialization
    
    public init(serialNumber: String) {
        self.serialNumber = serialNumber
    }
}
