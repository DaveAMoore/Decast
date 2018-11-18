//
//  RKCommand.swift
//  RemoteKit
//
//  Created by David Moore on 11/10/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import UIKit

/// Object that represents a specific command that is associated with a remote.
public struct RKCommand: Codable, Hashable {
    
    // MARK: - Types
    
    public typealias ID = String
    
    // MARK: - Properties
    
    /// User-presentable title of the command.
    public let localizedTitle: String
    
    /// Identifier for the command that will be used on the hardware for specific things.
    public let commandID: ID
    
    /// Creates a new command.
    public init(localizedTitle: String, commandID: ID) {
        self.localizedTitle = localizedTitle
        self.commandID = commandID
    }
}
