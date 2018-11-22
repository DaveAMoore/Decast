//
//  RFRegion.swift
//  RFCore
//
//  Created by David Moore on 7/24/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation
import AWSCore

/// Region representing the physical location of the container itself.
public enum RFRegion: String, Codable, Equatable, CaseIterable {
    case USEast1
    case USEast2
    case USWest1
    case USWest2
    case EUWest1
    case EUWest2
    case EUWest3
    case EUCentral1
    case APSoutheast1
    case APSoutheast2
    case APNortheast1
    case APNortheast2
    case APSouth1
    case SAEast1
    case CNNorth1
    case CACentral1
    case USGovWest1
    case CNNorthWest1
    
    /// Converted `RFRegion` to `AWSRegionType`.
    internal var regionType: AWSRegionType {
        switch self {
        case .USEast1:
            return .USEast1
        case .USEast2:
            return .USEast2
        case .USWest1:
            return .USWest1
        case .USWest2:
            return .USWest2
        case .EUWest1:
            return .EUWest1
        case .EUWest2:
            return .EUWest2
        case .EUWest3:
            return .EUWest3
        case .EUCentral1:
            return .EUCentral1
        case .APSoutheast1:
            return .APSoutheast1
        case .APSoutheast2:
            return .APSoutheast2
        case .APNortheast1:
            return .APNortheast1
        case .APNortheast2:
            return .APNortheast2
        case .APSouth1:
            return .APSouth1
        case .SAEast1:
            return .SAEast1
        case .CNNorth1:
            return .CNNorth1
        case .CACentral1:
            return .CACentral1
        case .USGovWest1:
            return .USGovWest1
        case .CNNorthWest1:
            return .CNNorthWest1
        }
    }
}
