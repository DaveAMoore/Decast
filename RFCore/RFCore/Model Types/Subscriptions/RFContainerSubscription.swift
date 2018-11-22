//
//  RFContainerSubscription.swift
//  RFCore
//
//  Created by David Moore on 8/1/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

/// A subscription for container. changes.
open class RFContainerSubscription: RFSubscription {

    // MARK: - Initialization
    
    /// Creates and returns a subscription for container changes.
    public init(subscriptionID: RFSubscription.ID) {
        super.init(subscriptionID: subscriptionID, subscriptionType: .container)
    }
}
