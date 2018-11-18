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
    func sessionManager(_ sessionManager: RKSessionManager, present viewController: UIViewController)
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
    
    // MARK: - Activation
    
    /// Activates the session manager by initiating an MQTT connection with IoT.
    func activate(completionHandler: ((Error?) -> Void)?) {
        
        
        /*(container.configuration.serviceConfiguration.credentialsProvider as! AWSCognitoIdentityCognitoIdentityProvider).
        
        container.configuration.serviceConfiguration.credentialsProvider.credentials().continueOnSuccessWith { task -> Any? in
            if let result = task.result {
                
                /*let t = AWSCognitoIdentityGetIdInput()!
                t.
                cognitoIdentityService.getId(<#T##request: AWSCognitoIdentityGetIdInput##AWSCognitoIdentityGetIdInput#>, completionHandler: <#T##((AWSCognitoIdentityGetIdResponse?, Error?) -> Void)?##((AWSCognitoIdentityGetIdResponse?, Error?) -> Void)?##(AWSCognitoIdentityGetIdResponse?, Error?) -> Void#>)*/
            } else if let error = task.error {
                
            }
            
            return nil
        }*/
        
        /*let t = AWSCognitoIdentityGetIdInput()!
        t.accountId = "232836439524"
        t.identityPoolId = "us-east-1:c8e757e4-e780-416f-8966-61bfb539110f"
        
        cognitoIdentityService.getId(t) { response, error in
            if let response = response {
                
            } else if let error = error {
                
            }
        }*/
        
        /*let i = AWSIoTAttachPolicyRequest()!
        i.target = "us-east-1:b75c8125-eebe-4b20-8454-67a5edda2359"
        i.policyName = "RemoteCoreTestingPolicy"
        iotService.attachPolicy(i) { error in
            
            if let error = error {
                fatalError("\(error.localizedDescription)")
            }
        }*/
        
        // Initiate a web socket connection. Note: This call determines if a connection is already being initialized.
        dataManager.connectUsingWebSocket(withClientId: RKSessionManager.clientID, cleanSession: true) { status in
            switch status {
            case .connected:
                completionHandler?(nil)
            case .connectionError:
                // FIXME: Pass the error back.
                fatalError("Socket connection failed.")
                // completionHandler?(nil)
            default:
                break
            }
        }
    }
    
    // MARK: - Messaging
    
    func sendSomething() {
        dataManager.publishData(Data(), onTopic: "", qoS: qualityOfService) {
            
        }
    }
}

// MARK: - Authentication Controller Delegate

extension RKSessionManager: RKAuthenticationControllerDelegate {
    
    func authenticationController(_ authenticationController: RKAuthenticationController,
                                  present viewController: UIViewController) {
        delegate?.sessionManager(self, present: viewController)
    }
}
