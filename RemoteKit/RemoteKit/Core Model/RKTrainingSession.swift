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
    
    /// Called when a fatal error occurred that caused the entire training session to fail.
    func trainingSession(_ trainingSession: RKTrainingSession, didFailWith error: Error)
    
    /// The training session is going to begin learning a new command.
    func trainingSession(_ trainingSession: RKTrainingSession, willLearn command: RKCommand)
    
    /// The training session learned a new command.
    func trainingSession(_ trainingSession: RKTrainingSession, didLearn command: RKCommand)
    
    /// All buttons should be pressed in no specific order (i.e., randomly) repeatedly.
    func trainingSessionDidRequestInclusiveArbitraryInput(_ trainingSession: RKTrainingSession)
    
    /// Input should be provided for the single command that is provided.
    func trainingSession(_ trainingSession: RKTrainingSession, didRequestInputFor command: RKCommand)
    
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
    
    // MARK: -
    
    /// Starts the training session.
    func start() {
        
    }
    
    func suspend() {
        
    }
    
    // MARK: - Message Handling
    
    /// Handles a response or training message.
    func handle(_ message: RKMessage) {
        switch message.type {
        case .training:
            break
        case .trainingResponse:
            break
        default:
            break
        }
    }
    
    // MARK: - Training
    
    public func createCommand(withLocalizedTitle localizedTitle: String, completionHandler: @escaping ((RKCommand?, Error?) -> Void)) {
        session.send(RKMessage.trainingMessage(for: remote, directive: Constants.Directives.createCommand))
    }
    
    public func learn(_ command: RKCommand) {
        session.send(RKMessage.trainingMessage(for: remote, with: command, directive: Constants.Directives.learnCommand))
    }
}
