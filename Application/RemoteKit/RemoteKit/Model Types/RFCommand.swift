//
//  RFCommand.swift
//  RemoteKit
//
//  Created by David Moore on 11/10/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import UIKit

/// Object that represents a specific command that is associated with a remote.
public struct RFCommand: Codable {
    
    public typealias ID = String
    
    // MARK: - Properties
    
    public var localizedTitle: String
    
    public var commandID: ID
}
