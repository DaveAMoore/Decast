//
//  RKSessionManager.swift
//  RemoteKit
//
//  Created by David Moore on 11/17/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation
import AWSIoT
import RFCore

public protocol RKSessionManagerDelegate: NSObjectProtocol {
    
    /// Called when the session manager is attempting to authenticate the user.
    ///
    /// - Parameters:
    ///   - viewController: View controller that will perform the authentication process.
    func sessionManager(_ sessionManager: RKSessionManager, presentAuthenticationViewController viewController: UIViewController)
}

/// Manages `RKSession` instances by controlling resources.
public final class RKSessionManager: NSObject {
    
    // MARK: - Constants
    
    /// Key representing the shared session manager endpoint.
    static let SessionManagerEndpointKey = "RKSessionManagerEndpoint"
    
    // MARK: - Properties
    
    /// Convenience method that uses `RFContainer.default` as the service manager's container.
    public static private(set) var shared: RKSessionManager = {
        let bundle = Bundle(for: RKSessionManager.self)
        
        // Retrieve the endpoint from the PLIST.
        guard let endpointString = bundle.infoDictionary?[SessionManagerEndpointKey] as? String else {
            preconditionFailure("RKSessionManagerEndpoint not found in Info.plist")
        }
        
        // Create and configure the service manager.
        let container = RFContainer(bundle: bundle)
        let serviceManager = RKSessionManager(container: container, endpoint: URL(string: endpointString)!)
        
        return serviceManager
    }()
    
    /// Unique identifier for this particular client.
    private static let clientID = UUID().uuidString
    
    /// Run loop for the data manager.
    private lazy var dataManagerRunLoop = RunLoop.current
    
    /// Delegate for the session manager.
    public weak var delegate: RKSessionManagerDelegate?
    
    /// Authentication controller instance used for authenticating the user when required.
    private var authenticationController: RKAuthenticationController
    
    /// Quality of service for the MQTT service.
    private let qualityOfService: AWSIoTMQTTQoS = .messageDeliveryAttemptedAtLeastOnce
    
    // Endpoint for the receiver to use with `dataManager`.
    private let endpoint: URL
    
    /// Dispatch queue to use for synchronizing networking.
    private let dataManagerQueue = DispatchQueue(label: "ca.mooredev.RemoteKit.RFSessionManager.dataManagerQueue")
    
    /// List of all subscribed topics.
    private(set) var subscribedTopics: Set<String> = []
    
    /// Boolean value indicating if the session manager is connected or not.
    private var isConnected: Bool {
        return dataManager.getConnectionStatus() == .connected
    }
    
    /// Identity of the user that is currently authenticated.
    private(set) var userID: String?
    
    /// Container to use for accessing adjacent resources.
    let container: RFContainer
    
    /// Cognito identity service associated with `container`.
    lazy var cognitoIdentityService: AWSCognitoIdentity = {
        return newCognitoIdentityService()
    }()
    
    /// `IoT` service associated with `container`.
    lazy var iotService: AWSIoT = {
        return newIoTService()
    }()
    
    /// `AWSIotDataManager` that is managed by the receiver.
    lazy var dataManager: AWSIoTDataManager = {
        return newDataManager()
    }()
    
    // MARK: - Initialization
    
    /// Returns a service manager that uses `container `for operational management.
    init(container: RFContainer, endpoint: URL) {
        self.container = container
        self.endpoint = endpoint
        self.authenticationController = RKAuthenticationController(container: container)
        
        // Call super.
        super.init()
        
        // Configure the authentication flow.
        self.container.configuration.credentials.shouldClearKeychain = false
        self.authenticationController.delegate = self
        self.container.configuration.delegate = self.authenticationController
    }
    
    // MARK: - Service Configuration
    
    func newCognitoIdentityService() -> AWSCognitoIdentity {
        let cognitoIdentityKey = "ca.mooredev.RemoteKit.RKSessionManager.AWSCognitoIdentity-\(UUID().uuidString)"
        AWSCognitoIdentity.register(with: container.configuration.serviceConfiguration, forKey: cognitoIdentityKey)
        
        let cognitoIdentityService = AWSCognitoIdentity(forKey: cognitoIdentityKey)
        
        return cognitoIdentityService
    }
    
    func newIoTService() -> AWSIoT {
        // Create a new service configuration and register it with AWSIoT.
        let iotKey = "ca.mooredev.RemoteKit.RKSessionManager.AWSIoT-\(UUID().uuidString)"
        AWSIoT.register(with: container.configuration.serviceConfiguration, forKey: iotKey)
        
        // Retrieve the registered service.
        let iotService = AWSIoT(forKey: iotKey)
        
        return iotService
    }
    
    func newDataManager() -> AWSIoTDataManager {
        // Setup an MQTT configuration.
        let lastWillAndTestament = AWSIoTMQTTLastWillAndTestament()
        let mqttConfiguration = AWSIoTMQTTConfiguration(keepAliveTimeInterval: 60,
                                                        baseReconnectTimeInterval: 1.0,
                                                        minimumConnectionTimeInterval: 20.0,
                                                        maximumReconnectTimeInterval: 128.0,
                                                        runLoop: dataManagerRunLoop,
                                                        runLoopMode: RunLoop.Mode.default.rawValue,
                                                        autoResubscribe: true,
                                                        lastWillAndTestament: lastWillAndTestament)
        
        // Create a service configuration that includes the endpoint.
        let serviceConfiguration = AWSServiceConfiguration(region: container.configuration.serviceConfiguration.regionType,
                                                           endpoint: AWSEndpoint(url: endpoint),
                                                           credentialsProvider: container.configuration.serviceConfiguration.credentialsProvider)!
        
        // Create a new service configuration and register it with AWSIoT.
        let dataManagerKey = "ca.mooredev.RemoteKit.RKSessionManager.AWSIoTDataManager-\(UUID().uuidString)"
        AWSIoTDataManager.register(with: serviceConfiguration, with: mqttConfiguration,
                                   forKey: dataManagerKey)
        
        // Retrieve the registered service.
        let dataManager = AWSIoTDataManager(forKey: dataManagerKey)
        
        return dataManager
    }
    
    // MARK: - Helper Methods
    
    /// Creates a topic any given device, associating it with the current user identity.
    func topic(for device: RKDevice) -> String {
        return Constants.topic(for: device, withUserID: userID!)
    }
    
    private func fetchUserID(completionHandler: @escaping ((String?, Error?) -> Void)) {
        let credentialsProvider = container.configuration.serviceConfiguration.credentialsProvider as? AWSCognitoCredentialsProvider
        credentialsProvider?.getIdentityId().continueOnSuccessWith { task -> Any? in
            completionHandler(task.result as String?, task.error)
            return nil
        }
    }
    
    // MARK: - Activation
    
    /// Activates the session manager by initiating an MQTT connection with IoT.
    func activate(completionHandler: ((Error?) -> Void)?) {
        fetchUserID { userID, error in
            self.userID = userID
            
            var didCallCompletionHandler = false
            
            self.dataManager.connectUsingWebSocket(withClientId: RKSessionManager.clientID, cleanSession: true) { status in
                guard !didCallCompletionHandler else { return }
                switch status {
                case .connected:
                    completionHandler?(nil)
                    didCallCompletionHandler = true
                case .connectionError:
                    completionHandler?(RKError.connectionFailure)
                    didCallCompletionHandler = false
                default:
                    break
                }
            }
        }
    }
    
    /// Deactivates the session manager by disconnecting from the MQTT connection.
    func deactivate() {
        dataManager.disconnect()
    }
    
    // MARK: - Connection Interface
    
    /// Subscribes to a particular topic with a default quality of service, then provides messages received on the topic.
    ///
    /// - Parameters:
    ///   - topic: The topic that will be subscribed to.
    ///   - messageHandler: Called when messages are received on the topic.
    ///   - completionHandler: Called when the subscription is completed.
    func subscribe(toTopic topic: String, messageHandler: @escaping ((Data) -> Void), completionHandler: (() -> Void)?) {
        dataManager.subscribe(toTopic: topic, qoS: qualityOfService, messageCallback: messageHandler) {
            self.subscribedTopics.insert(topic)
            completionHandler?()
        }
    }
    
    /// Unsubscribes from a topic immediately.
    func unsubscribe(fromTopic topic: String) {
        dataManager.unsubscribeTopic(topic)
        subscribedTopics.remove(topic)
    }
    
    /// Publishes data to a particular topic asynchronously.
    func publish(_ data: Data, toTopic topic: String, completionHandler: (() -> Void)?) {
        dataManager.publishData(data, onTopic: topic, qoS: qualityOfService) {
            completionHandler?()
        }
    }
    
    // MARK: - Device Management
    
    /// Fetches all devices associated with this user.
    ///
    /// - Parameter completionHandler: Called when the devices have been fetched.
    public func fetchAllDevices(completionHandler: @escaping (([RKDevice]?, Error?) -> Void)) {
        fetchUserID { userID, error in
            guard let userID = userID else { return completionHandler(nil, error) }
            
            let predicate = NSPredicate(format: "Owner == %@", userID)
            let query = RFQuery(recordType: Constants.RecordTypes.device, predicate: predicate)
            
            self.container.perform(query) { queriedRecords, queryError in
                if let queriedRecords = queriedRecords {
                    do {
                        let decoder = RFRecordDecoder()
                        let devices = try queriedRecords.map { try decoder.decode(RKDevice.self, from: $0) }
                        completionHandler(devices, nil)
                    } catch {
                        completionHandler(nil, error)
                    }
                } else {
                    completionHandler(nil, error)
                }
            }
        }
    }
    
    // MARK: - Remote Management
    
    /// Saves a remote to the cloud as the current user.
    ///
    /// - Parameters:
    ///   - remote: Remote that will be saved remotely.
    ///   - completionHandler: Called when the remote has been saved, or if an error occurred.
    public func save(_ remote: RKRemote, completionHandler: @escaping ((Error?) -> Void)) {
        fetchUserID { userID, error in
            guard let userID = userID else { return completionHandler(error) }
            
            do {
                let record = RFRecord(recordType: Constants.RecordTypes.remote, recordID: RFRecord.ID(recordName: remote.remoteID))
                record["Owner"] = userID
                
                let encoder = RFRecordEncoder(for: record)
                try encoder.encode(remote)
                
                self.container.save(record) { savedRecord, saveError in
                    completionHandler(saveError)
                }
            } catch {
                completionHandler(error)
            }
        }
    }
    
    /// Fetches all remotes for a particular device.
    ///
    /// - Parameters:
    ///   - device: The device which the remotes are associated with.
    ///   - completionHandler: Called when the remotes have been fetched, or an error occurred.
    public func fetchRemotes(for device: RKDevice, completionHandler: @escaping (([RKRemote]?, Error?) -> Void)) {
        let fetchOperation = RFFetchRecordsOperation(recordIDs: device.remoteIDs.map { RFRecord.ID(recordName: $0) })
        fetchOperation.fetchRecordsCompletionBlock = { fetchedRecordsByRecordID, error in
            guard let fetchedRecords = fetchedRecordsByRecordID?.values else { return completionHandler(nil, error) }
            
            do {
                let decoder = RFRecordDecoder()
                let remotes = try fetchedRecords.map { try decoder.decode(RKRemote.self, from: $0) }
                
                completionHandler(remotes, nil)
            } catch {
                completionHandler(nil, error)
            }
        }
        
        container.add(fetchOperation)
    }
    
    /// Fetches all remotes for the current user.
    ///
    /// - Parameter completionHandler: Called when the remotes have been fetched, or an error occurred.
    public func fetchAllRemotes(completionHandler: @escaping (([RKRemote]?, Error?) -> Void)) {
        fetchUserID { userID, error in
            guard let userID = userID else { return completionHandler(nil, error) }
            
            let predicate = NSPredicate(format: "Owner == %@", userID)
            let query = RFQuery(recordType: Constants.RecordTypes.remote, predicate: predicate)
            
            self.container.perform(query) { fetchedRecords, error in
                if let fetchedRecords = fetchedRecords {
                    do {
                        let decoder = RFRecordDecoder()
                        let remotes = try fetchedRecords.map { try decoder.decode(RKRemote.self, from: $0) }
                        
                        completionHandler(remotes, nil)
                    } catch {
                        completionHandler(nil, error)
                    }
                } else {
                    completionHandler(nil, error)
                }
            }
        }
    }
}

// MARK: - Authentication Controller Delegate

extension RKSessionManager: RKAuthenticationControllerDelegate {
    
    func authenticationController(_ authenticationController: RKAuthenticationController,
                                  present viewController: UIViewController) {
        delegate?.sessionManager(self, presentAuthenticationViewController: viewController)
    }
}
