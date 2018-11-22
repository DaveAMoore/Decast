//
//  Constants.swift
//  RemoteKit
//
//  Created by David Moore on 11/17/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

struct Constants {
    
    static func topic(for device: RKDevice, withUserID userID: String) -> String {
        return "remote_core/account/\(userID)/\(device.serialNumber)"
    }
    
    struct RecordTypes {
        static let remote = "Remote"
        static let device = "Device"
    }
}
