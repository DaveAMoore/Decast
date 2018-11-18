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
    
    struct Directives {
        static let startTrainingSession =   "startTrainingSession"
        static let suspendTrainingSession = "suspendTrainingSession"
        static let createCommand =          "createCommandWithLocalizedTitle"
        static let learnCommand =           "learnCommand"
        
        static let trainingSessionDidBegin =                            "trainingSessionDidBegin"
        static let trainingSessionDidFailWithError =                    "trainingSessionDidFailWithError"
        static let trainingSessionWillLearnCommand =                    "trainingSessionWillLearnCommand"
        static let trainingSessionDidLearnCommand =                     "trainingSessionDidLearnCommand"
        static let trainingSessionDidRequestInclusiveArbitraryInput =   "trainingSessionDidRequestInclusiveArbitraryInput"
        static let trainingSessionDidRequestInputForCommand =           "trainingSessionDidRequestInputForCommand"
        static let trainingSessionDidRequestExclusiveArbitraryInput =   "trainingSessionDidRequestExclusiveArbitraryInput"
    }
}
