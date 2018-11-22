//
//  RFSubscription.swift
//  RFCore
//
//  Created by David Moore on 8/1/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

/// Use a CKSubscription object to track changes occurring on the server.
open class RFSubscription: NSObject {

    // MARK: - Types
    
    public typealias ID = String
    
    /// Constants that identify a subscription’s behavior.
    public enum SubscriptionType: Int, Codable, CaseIterable {
        case container
    }
    
    // MARK: - Properties
    
    /// Unique identifier for the specific subscription; equivialent to the topic ARN.
    public let subscriptionID: ID
    
    /// Storage for device token.
    private var _deviceToken: String?
    
    /// Device token to use for the subscription.
    public var deviceToken: String {
        guard let deviceToken = _deviceToken else { preconditionFailure("'deviceToken' is nil") }
        return deviceToken
    }
    
    /// The type of behavior provided by the subscription.
    public let subscriptionType: SubscriptionType
    
    // MARK: - Initialization
    
    internal init(subscriptionID: ID, subscriptionType: SubscriptionType) {
        self.subscriptionID = subscriptionID
        self.subscriptionType = subscriptionType
        super.init()
    }
    
    private override init() {
        fatalError("Not supported")
    }
    
    // MARK: - Tokenization
    
    /// Sets the device token to the provided data.
    public func setDeviceToken(to data: Data) {
        _deviceToken = data.map { String(format: "%02.2hhx", $0) }.joined()
    }
}
