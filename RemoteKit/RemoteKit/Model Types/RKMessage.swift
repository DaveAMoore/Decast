//
//  RKMessage.swift
//  RemoteKit
//
//  Created by David Moore on 11/13/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

/// Core component of messaging *remote_core*.
struct RKMessage: Codable, Equatable {
    
    // MARK: - Types
    
    typealias ID = String
    
    /// Represents a particular kind of `RKMessage`.
    enum Kind: Int, Codable {
        case `default`          = 0
        case training           = 1
        case command            = 2
        case commandResponse    = 3
        case trainingResponse   = 4
    }
    
    // MARK: - Properties
    
    /// Unique identifier for the sender of the message.
    var senderID: ID
    
    /// Unique identifier for a specific message.
    var messageID: ID
    
    /// Indicates the type of message that is represented by the receiver.
    var type: Kind
    
    /// Remote the message is pertaining to.
    var remote: RKRemote?
    
    /// The command that is being communicated.
    var command: RKCommand?
    
    /// Error for response messages.
    var error: RKError?
    
    /// The intention of a message.
    var directive: Directive?
    
    // MARK: - Initialization
    
    private init(type: Kind, senderID: ID = RKSessionManager.shared.userID!, remote: RKRemote?, command: RKCommand?, directive: Directive?) {
        self.senderID = senderID
        self.messageID = UUID().uuidString
        self.type = type
        self.remote = remote
        self.command = command
        self.directive = directive
    }
    
    /*init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.senderID = try container.decode(ID.self, forKey: .senderID)
        self.messageID = try container.decode(ID.self, forKey: .messageID)
        self.type = try container.decode(Kind.self, forKey: .type)
        self.remote = try? cont
    }*/
    
    static func commandMessage(for command: RKCommand, with remote: RKRemote) -> RKMessage {
        return RKMessage(type: .command, remote: remote, command: command, directive: nil)
    }
    
    static func trainingMessage(for remote: RKRemote, with command: RKCommand? = nil, directive: Directive? = nil) -> RKMessage {
        let message = RKMessage(type: .training, remote: remote, command: command, directive: directive)
        return message
    }
    
    static func commandResponse(with error: RKError? = nil) -> RKMessage {
        var message = RKMessage(type: .commandResponse, remote: nil, command: nil, directive: nil)
        message.error = error
        
        return message
    }
    
    static func trainingResponse(with error: RKError? = nil) -> RKMessage {
        var message = RKMessage(type: .trainingResponse, remote: nil, command: nil, directive: nil)
        message.error = error
        
        return message
    }
}
