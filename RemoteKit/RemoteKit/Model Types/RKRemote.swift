//
//  RKRemote.swift
//  RemoteKit
//
//  Created by David Moore on 11/10/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation
import RFCore

/// Abstraction for a remote object.
open class RKRemote: Codable {

    // MARK: - Types
    
    public typealias ID = String
    
    // MARK: - Properties
    
    /// Title of the remote; this may be presented to the user.
    open private(set) var localizedTitle: String
    
    /// Unique identifier for a particular remote.
    open private(set) var remoteID: ID
    
    /// Collection of commands
    open private(set) var commands: [RKCommand]
    
    // MARK: - Initialization
    
    public init(localizedTitle: String, remoteID: ID, commands: [RKCommand] = []) {
        self.localizedTitle = localizedTitle
        self.remoteID = remoteID
        self.commands = commands
    }
}
