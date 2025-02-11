//
//  RKSession.swift
//  RemoteKit
//
//  Created by David Moore on 11/10/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation
import RFCore
import AWSIoT

public protocol RKSessionDelegate: NSObjectProtocol {
    func sessionDidActivate(_ session: RKSession)
    func session(_ session: RKSession, didFailWithError error: Error)
    func session(_ session: RKSession, didSendCommand command: RKCommand, forRemote remote: RKRemote)
    func session(_ session: RKSession, didFailToSendCommand command: RKCommand, forRemote remote: RKRemote, withError error: Error)
}

/// Conduit for accessing RFCore-associated resources, in addition to providing access to IoT resources.
public class RKSession: NSObject {
    
    // MARK: - Types
    
    public enum ActivationState: Int {
        /// The session is not activated. When in this state, no communication occurs between a particular device and the host application.
        case notActivated
        
        /// The session is active and the external device and the host may communicate with each other freely.
        case activated
    }
    
    // MARK: - Properties
    
    /// Object that manages the session internally.
    public let sessionManager: RKSessionManager
    
    /// Representation for a particular device.
    public let device: RKDevice
    
    /// Hash table of training sessions that are registered with the receiver.
    private lazy var trainingSessions = NSHashTable<RKTrainingSession>.weakObjects()
    
    /// The training session that is currently ongoing.
    private var currentTrainingSession: RKTrainingSession?
    
    /// Boolean value indicating if the receiver currently has an active training session.
    public var hasActiveTrainingSession: Bool {
        return currentTrainingSession != nil
    }
    
    /// Default topic that should be used.
    private var defaultTopic: String {
        return sessionManager.topic(for: device)
    }
    
    /// Current activation state of the session.
    public var activationState: ActivationState {
        switch sessionManager.dataManager.getConnectionStatus() {
        case .connected:
            return .activated
        default:
            return .notActivated
        }
    }
    
    /// Delegate that will be called for changes in state.
    public weak var delegate: RKSessionDelegate?
    
    // MARK: - Initialization
    
    /// Creates a new session for a particular device.
    public init(device: RKDevice) {
        self.sessionManager = .shared
        self.device = device
    }
    
    deinit {
        if currentTrainingSession != nil {
            suspend(currentTrainingSession!)
        }
    }
    
    // MARK: - Configuration
    
    /// Activates the session asynchronously.
    public func activate() {
        /*let record = RFRecord(recordType: "Foo", recordID: RFRecord.ID(recordName: UUID().uuidString))
        sessionManager.container.save(record) { savedRecord, error in
            print("Saved: \(error?.localizedDescription ?? "")")
        }*/
        
        // Activate the session manager.
        sessionManager.activate { [weak self] error in
            guard error == nil else {
                self?.delegate?.session(self!, didFailWithError: error!)
                return
            }
            
            // Subscribe to the default topic.
            self?.sessionManager.subscribe(toTopic: self!.defaultTopic, messageHandler: { [weak self] data in
                guard let strongSelf = self else { return }
                
                do {
                    // Decode the message.
                    let decoder = JSONDecoder()
                    let message = try decoder.decode(RKMessage.self, from: data)
                    
                    // Handle the message if it did not originate from this device.
                    if message.senderID != strongSelf.sessionManager.userID {
                        strongSelf.handle(message)
                    }
                } catch {
                    fatalError("Failed to decode message: \(error.localizedDescription)")
                }
            }, completionHandler: nil)
            
            // Call the appropriate delegate method.
            self?.delegate?.sessionDidActivate(self!)
        }
    }
    
    // MARK: - Message Handling
    
    private func handle(_ message: RKMessage) {
        switch message.type {
        case .commandResponse:
            if let command = message.command, let remote = message.remote {
                if let error = message.error {
                    delegate?.session(self, didFailToSendCommand: command, forRemote: remote, withError: error)
                } else {
                    delegate?.session(self, didSendCommand: command, forRemote: remote)
                }
            }
        case .training, .trainingResponse:
            currentTrainingSession?.handle(message)
        default:
            break
        }
    }
    
    // MARK: - Training Interface
    
    /// Creates a new training session for a remote.
    public func newTrainingSession(for remote: RKRemote) -> RKTrainingSession {
        let trainingSession = RKTrainingSession(device: device, remote: remote, session: self)
        trainingSessions.add(trainingSession)
        
        return trainingSession
    }
    
    /// Makes sure the training session is registered with the receiver.
    private func enforceRegistration(of trainingSession: RKTrainingSession) {
        // Ensure the training session is registered with the receiver.
        if !trainingSessions.contains(trainingSession) {
            preconditionFailure("Expected 'trainingSession' to be registered with the receiver.")
        }
    }
    
    /// Starts a training session if one is not already active.
    ///
    /// - Note: It is a programmer error to attempt to start a training session when `hasActiveTrainingSession` is `true`.
    public func start(_ trainingSession: RKTrainingSession) {
        guard !hasActiveTrainingSession else {
            preconditionFailure("Expected 'hasActiveTrainingSession' to be false.")
        }

        enforceRegistration(of: trainingSession)
        
        // Start the training session and keep a reference to it.
        currentTrainingSession = trainingSession
        trainingSession.start()
    }
    
    /// Suspends the provided training session if it is currently active. When `trainingSession` is not active this is a no-op.
    public func suspend(_ trainingSession: RKTrainingSession) {
        guard trainingSession == currentTrainingSession else { return }
        
        // Unwrap the training session.
        if let trainingSession = currentTrainingSession {
            // Suspend and release it.
            trainingSession.suspend()
            currentTrainingSession = nil
        }
    }
    
    // MARK: - Sending Messages
    
    /// Posts a message to the default topic.
    ///
    /// - Parameter message: The message that will be sent.
    func send(_ message: RKMessage) {
        do {
            // Try to encode the message.
            let encoder = JSONEncoder()
            let messageData = try encoder.encode(message)
            
            // Publish the message.
            sessionManager.publish(messageData, toTopic: defaultTopic, completionHandler: nil)
        } catch {
            fatalError("Failed to encode message: \(error.localizedDescription)")
        }
    }
    
    /// Sends a command using the device for a given remote.
    ///
    /// - Parameters:
    ///   - command: The command that will be sent.
    ///   - remote: The remote that will be used to send the command.
    public func send(_ command: RKCommand, for remote: RKRemote) {
        let message = RKMessage.commandMessage(for: command, with: remote)
        send(message)
    }
}
