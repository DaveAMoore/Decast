//
//  RKMessage.swift
//  RemoteKit
//
//  Created by David Moore on 11/13/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

/// Core component of messaging *remote_core*.
public struct RKMessage: Codable, Equatable {
    
    // MARK: - Types
    
    public typealias ID = String
    
    /// Represents a particular kind of `RKMessage`.
    public enum Kind: Int, Codable {
        case `default`
        case training
        case command
    }
    
    // MARK: - Properties
    
    /// Unique identifier for a specific message.
    public var messageID: ID
    
    /// Indicates the type of message that is represented by the receiver.
    public var type: Kind
    
    /// The device which this message pertains to.
    public var device: RKDevice?
}
