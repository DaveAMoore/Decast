//
//  RKError.swift
//  RemoteKit
//
//  Created by David Moore on 11/18/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

/// RemoteKit error representation.
public enum RKError: Int, Codable, Error {
    case connectionFailure          = 1
    case unknown                    = -1
    case noSignalWhileTraining      = -2
    case trainingAlreadyInSession   = -3
    case invalidDirective           = -4
    case invalidParameters          = -5
    case noTrainingSession          = -6
}
