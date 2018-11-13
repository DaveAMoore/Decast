//
//  RFRemote.swift
//  RemoteKit
//
//  Created by David Moore on 11/10/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation
import RFCore

/// Abstraction for a remote object.
open class RFRemote: Codable {

    // MARK: - Properties
    
    open internal(set) var commands: [RFCommand] = []
    
    // MARK: - Initialization
    
    
}
