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
open class RKRemote: Codable, Equatable {

    // MARK: - Types
    
    public typealias ID = String
    
    // MARK: - Properties
    
    /// Title of the remote; this may be presented to the user.
    public let localizedTitle: String
    
    /// Unique identifier for a particular remote.
    public let remoteID: ID
    
    /// Collection of commands
    open private(set) var commands: [RKCommand]
    
    // MARK: - Initialization
    
    /// Creates a new remote with the provided options.
    init(localizedTitle: String, remoteID: ID, commands: [RKCommand] = []) {
        self.localizedTitle = localizedTitle
        self.remoteID = remoteID
        self.commands = commands
    }
    
    /// Creates a new remote with a localized title.
    public convenience init(localizedTitle: String) {
        self.init(localizedTitle: localizedTitle, remoteID: "9526245E-4D5F-4FFD-8528-A5058C24EAA0"/*UUID().uuidString*/)
        self.commands = []
    }
    
    // MARK: - Equatable
    
    public static func ==(lhs: RKRemote, rhs: RKRemote) -> Bool {
        return lhs.localizedTitle == rhs.localizedTitle && lhs.remoteID == rhs.remoteID && lhs.commands == rhs.commands
    }
    
    // MARK: - Command Management
    
    /// Adds a new command to the remote.
    func add(_ command: RKCommand) {
        commands.append(command)
    }
}
