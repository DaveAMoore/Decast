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

/// Conduit for accessing RFCore-associated resources, in addition to providing access to IoT resources.
open class RKSession: NSObject {
    
    // MARK: - Properties
    
    /// Container to use for accessing adjacent resources.
    public let container: RFContainer
    
    // MARK: - Initialization
    
    public init(container: RFContainer) {
        self.container = container
    }
    
    // MARK: - Convenience Methods
    
    open func send(_ message: RKMessage, completionHandler: @escaping ((String?, Error?) -> Void)) {
        
    }
    
    open func send(_ command: RKCommand, for remote: RKRemote, completionHandler: @escaping (() -> Void)) {
        
    }
}
