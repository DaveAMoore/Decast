//
//  RFError.swift
//  RFCore
//
//  Created by David Moore on 8/7/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

/// Error that can be returned by RFCore.
public struct RFError: Error {
    
    // MARK: - Definitions
    
    /// Codes used to uniquely identify an error.
    public enum Code: Int {
        case partialFailure
        case unknown
    }
    
    /// Error domain for an `RFError`.
    public static let errorDomain = "RFErrorDomain"
    
    // MARK: - Properties
    
    /// Code used to identify a particular type of error.
    public let code: Code
    
    /// Partial failures will contain various errors within a particular
    public var partialErrorsByItemID: [AnyHashable: Error]?
    
    /// Information that may be pertinent for the issue.
    public var userInfo: [String: Any]?
    
    /// An error that underlies the interpretation of the receiver.
    public var underlyingError: Error?
    
    // MARK: - Initialization
    
    /// Creates and returns a new error with a particular code.
    public init(_ code: Code) {
        self.code = code
    }
    
    /// Creates and returns an `RFError` with a `.partialFailure` code with the `partialErrorsByItemID` property populated.
    internal static func partialFailure(with error: Error, forItemID itemID: AnyHashable) -> RFError {
        var _error = RFError(.partialFailure)
        _error.addPartialError(error, forItemID: itemID)
        
        return _error
    }
    
    // MARK: - Interface
    
    /// Updates an existing error that can be mutated with a new error for a particular item identifier.
    internal static func update(_ mutableError: inout RFError?, withPartialError partialError: Error?, forItemID itemID: AnyHashable) {
        guard let partialError = partialError else { return }
        
        if mutableError == nil {
            mutableError = RFError.partialFailure(with: partialError, forItemID: itemID)
        } else {
            mutableError?.addPartialError(partialError, forItemID: itemID)
        }
    }
    
    /// Adds a new partial error to the `partialErrorsByItemID` dictionary.
    ///
    /// - Parameters:
    ///   - error: Error that will be added to the dictionary.
    ///   - itemID: Unique identifier that is related to the item the error occurred for.
    internal mutating func addPartialError(_ error: Error, forItemID itemID: AnyHashable) {
        if partialErrorsByItemID == nil {
            partialErrorsByItemID = [itemID: error]
        } else {
            partialErrorsByItemID?[itemID] = error
        }
    }
}

extension RFError: LocalizedError {
    
    /// Localized description for the error.
    public var localizedDescription: String {
        switch code {
        case .partialFailure:
            return NSLocalizedString("A partial error occurred.", comment: "")
        case .unknown:
            return NSLocalizedString("An unknown error occurred.", comment: "")
        }
    }
}
