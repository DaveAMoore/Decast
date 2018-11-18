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
            
            //var didReturn = false
            
            self.dataManager.connectUsingWebSocket(withClientId: RKSessionManager.clientID, cleanSession: true) { status in
                switch status {
                case .connected:
                    completionHandler?(nil)
                case .connectionError:
                    // FIXME: Pass the error back.
                    fatalError("Socket connection failed.")
                    // completionHandler?(nil)
                    break
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
}

// MARK: - Authentication Controller Delegate

extension RKSessionManager: RKAuthenticationControllerDelegate {
    
    func authenticationController(_ authenticationController: RKAuthenticationController,
                                  present viewController: UIViewController) {
        delegate?.sessionManager(self, presentAuthenticationViewController: viewController)
    }
}
