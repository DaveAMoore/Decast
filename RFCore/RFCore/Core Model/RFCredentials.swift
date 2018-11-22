//
//  RFCredentials.swift
//  RFCore
//
//  Created by David Moore on 7/24/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation
import AWSCognitoIdentityProvider

/// Object representing a pool from which user identities can be fetched.
open class RFCredentials: Codable, Equatable {
    
    // MARK: - Properties
    
    /// Client identifier for the application used by Cognito user pools.
    open private(set) var applicationClientID: String
    
    /// CLient secret that is used to verify the authentication between the client and Cognito.
    open private(set) var applicationClientSecret: String
    
    /// Identifier of the user pool within a particular federation.
    open private(set) var poolID: String
    
    /// Identity pool identifier for a specific identity pool that is associated with the user pool.
    open private(set) var identityPoolID: String
    
    /// Region which the user pool is contained within.
    open private(set) var region: RFRegion
    
    /// Boolean value indicating if the keychain should be cleared.
    open var shouldClearKeychain: Bool = false
    
    // MARK: - Initialization
    
    /// Returns an `RFCredentials` that has been configured with the provided parameters.
    public init(applicationClientID: String, applicationClientSecret: String, poolID: String, identityPoolID: String, region: RFRegion) {
        self.applicationClientID = applicationClientID
        self.applicationClientSecret = applicationClientSecret
        self.poolID = poolID
        self.identityPoolID = identityPoolID
        self.region = region
    }
    
    // MARK: - AWS
    
    /// Creates and returns a credential provider for a particular service configuration.
    internal func newCredentialsProvider(with configuration: AWSServiceConfiguration) -> AWSCredentialsProvider {
        // Create the configuration and register it.
        let userPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: applicationClientID,
                                                                            clientSecret: applicationClientSecret,
                                                                            poolId: poolID)
        
        // Register the configuration.
        let userPoolKey = "ca.mooredev.RFCore.RFCredentials.AWSCongitoIdentityUserPool"
        AWSCognitoIdentityUserPool.register(with: configuration, userPoolConfiguration: userPoolConfiguration,
                                            forKey: userPoolKey)
        
        // Retrieve the user pool.
        let userPool = AWSCognitoIdentityUserPool(forKey: userPoolKey)
        
        // Create a credentials provider.
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: region.regionType, identityPoolId: identityPoolID,
                                                                identityProviderManager: userPool)
        
        // Clear the keychain if expected.
        if shouldClearKeychain {
            userPool.clearAll()
            credentialsProvider.clearKeychain()
            credentialsProvider.clearCredentials()
            credentialsProvider.invalidateCachedTemporaryCredentials()
        }
        
        return credentialsProvider
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case applicationClientID = "ApplicationClientID"
        case applicationClientSecret = "ApplicationClientSecret"
        case poolID = "PoolID"
        case identityPoolID = "IdentityPoolID"
        case region = "Region"
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: RFCredentials, rhs: RFCredentials) -> Bool {
        return lhs.applicationClientID == rhs.applicationClientID && lhs.applicationClientSecret == rhs.applicationClientSecret && lhs.poolID == rhs.poolID && lhs.identityPoolID == rhs.identityPoolID && lhs.region == rhs.region
    }
}
