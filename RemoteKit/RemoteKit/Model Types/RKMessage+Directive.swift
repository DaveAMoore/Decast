//
//  RKMessage+Directive.swift
//  RemoteKit
//
//  Created by David Moore on 11/18/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

extension RKMessage {
    
    /// Representation of a Directive.
    enum Directive: String, Codable, Hashable {
        case startTrainingSession = "startTrainingSession"
        case suspendTrainingSession = "suspendTrainingSession"
        case createCommand = "createCommandWithLocalizedTitle"
        case learnCommand = "learnCommand"
        case trainingSessionDidBegin = "trainingSessionDidBegin"
        case trainingSessionDidFailWithError = "trainingSessionDidFailWithError"
        case trainingSessionWillLearnCommand = "trainingSessionWillLearnCommand"
        case trainingSessionDidLearnCommand = "trainingSessionDidLearnCommand"
        case trainingSessionDidRequestInclusiveArbitraryInput = "trainingSessionDidRequestInclusiveArbitraryInput"
        case trainingSessionDidRequestInputForCommand = "trainingSessionDidRequestInputForCommand"
        case trainingSessionDidRequestExclusiveArbitraryInput = "trainingSessionDidRequestExclusiveArbitraryInput"
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.init(rawValue: try container.decode(RawValue.self))!
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }
}
