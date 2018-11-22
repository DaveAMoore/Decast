//
//  RKTrainingSession.swift
//  RemoteKit
//
//  Created by David Moore on 11/13/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

public protocol RKTrainingSessionDelegate: NSObjectProtocol {
    
    /// Training session is beginning.
    func trainingSessionDidBegin(_ trainingSession: RKTrainingSession)
    
    /// Called when the training session created a new command.
    func trainingSession(_ trainingSession: RKTrainingSession, didCreateCommand command: RKCommand)
    
    /// Called when the training session failed to create a new command.
    func trainingSession(_ trainingSession: RKTrainingSession, didFailToCreateCommandWithError error: Error)
    
    /// Called when a fatal error occurred that caused the entire training session to fail.
    func trainingSession(_ trainingSession: RKTrainingSession, didFailWithError error: Error)
    
    /// The training session is going to begin learning a new command.
    func trainingSession(_ trainingSession: RKTrainingSession, willLearnCommand command: RKCommand)
    
    /// The training session learned a new command.
    func trainingSession(_ trainingSession: RKTrainingSession, didLearnCommand command: RKCommand)
    
    /// All buttons should be pressed in no specific order (i.e., randomly) repeatedly.
    func trainingSessionDidRequestInclusiveArbitraryInput(_ trainingSession: RKTrainingSession)
    
    /// Input should be provided for the single command that is provided.
    func trainingSession(_ trainingSession: RKTrainingSession, didRequestInputForCommand command: RKCommand)
    
    /// A single random command should be pressed repeatedly.
    func trainingSessionDidRequestExclusiveArbitraryInput(_ trainingSession: RKTrainingSession)
}

/// Object that represents a session where training of a remote takes place.
public class RKTrainingSession: NSObject {
    
    // MARK: - Properties
    
    /// Device the remote is being trained with.
    public let device: RKDevice
    
    /// Remote that is being trained.
    public let remote: RKRemote
    
    /// Session that is being used for communication.0
    internal var session: RKSession
    
    /// Delegate that will be called during the lifecycle of the receiver.
    public weak var delegate: RKTrainingSessionDelegate?
    
    // MARK: - Initialization
    
    /// Creates a new training session based on a remote.
    init(device: RKDevice, remote: RKRemote, session: RKSession) {
        self.device = device
        self.remote = remote
        self.session = session
    }
    
    // MARK: - Messaging
    
    /// Sends a message with a given directive and optional command.
    func sendMessage(withDirective directive: RKMessage.Directive, command: RKCommand? = nil) {
        session.send(RKMessage.trainingMessage(for: remote, with: command, directive: directive))
    }
    
    // MARK: - State Management
    
    /// Starts the training session.
    func start() {
        sendMessage(withDirective: .startTrainingSession)
    }
    
    /// Suspends the training session.
    func suspend() {
        sendMessage(withDirective: .suspendTrainingSession)
    }
    
    // MARK: - Message Handling
    
    /// Handles a response or training message.
    func handle(_ message: RKMessage) {
        guard message.type == .training ||
            message.type == .trainingResponse,
            let directive = message.directive,
            let delegate = delegate else { return }
        
        switch directive {
        case .trainingSessionDidBegin:
            delegate.trainingSessionDidBegin(self)
        case .trainingSessionDidFailWithError:
            delegate.trainingSession(self, didFailWithError: message.error ?? RKError.unknown)
        case .createCommand:
            if let command = message.command {
                delegate.trainingSession(self, didCreateCommand: command)
            } else {
                delegate.trainingSession(self, didFailToCreateCommandWithError: message.error ?? RKError.unknown)
            }
        case .trainingSessionWillLearnCommand:
            if let command = message.command {
                delegate.trainingSession(self, willLearnCommand: command)
            }
        case .trainingSessionDidLearnCommand:
            if let command = message.command {
                remote.add(command)
                delegate.trainingSession(self, didLearnCommand: command)
            }
        case .trainingSessionDidRequestInputForCommand:
            if let command = message.command {
                delegate.trainingSession(self, didRequestInputForCommand: command)
            }
        case .trainingSessionDidRequestInclusiveArbitraryInput:
            delegate.trainingSessionDidRequestInclusiveArbitraryInput(self)
        case .trainingSessionDidRequestExclusiveArbitraryInput:
            delegate.trainingSessionDidRequestExclusiveArbitraryInput(self)
        default:
            break
        }
    }
    
    // MARK: - Training
    
    /// Creates a new command with a localized title. The command will be returned through a delegate callback.
    public func createCommand(withLocalizedTitle localizedTitle: String) {
        sendMessage(withDirective: .createCommand, command: RKCommand(localizedTitle: localizedTitle, commandID: ""))
    }
    
    /// Starts training the remote to learn a new command.
    public func learn(_ command: RKCommand) {
        sendMessage(withDirective: .learnCommand, command: command)
    }
}
