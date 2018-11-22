//
//  RFContainer+Configuration.swift
//  RFCore
//
//  Created by David Moore on 7/24/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation
import AWSCognitoIdentityProvider
import AWSS3

extension RFContainer {
    /// A collection of properties that describes how an RFContainer should behave.
    open class Configuration: Codable, Equatable {
        
        // MARK: - Properties
        
        /// User pool for the container's authentication purposes.
        open private(set) var credentials: RFCredentials
        
        /// Region which the container is stored in.
        open private(set) var region: RFRegion
        
        /// Service configuration directly associated with this configuration.
        final public lazy var serviceConfiguration: AWSServiceConfiguration = {
            return newServiceConfiguration()
        }()
        
        /// Delegate used for authentication purposes.
        open weak var delegate: AWSCognitoIdentityInteractiveAuthenticationDelegate? {
            get {
                let credentialsProvider = serviceConfiguration.credentialsProvider as? AWSCognitoCredentialsProvider
                let userPool = credentialsProvider?.identityProvider as? AWSCognitoIdentityUserPool
                return userPool?.delegate
            } set {
                __serviceConfigurationUserPool?.delegate = newValue
            }
        }
        
        /// Cognito identity user pool to use for various interfacing capabilities.
        final public var __serviceConfigurationUserPool: AWSCognitoIdentityUserPool? {
            let credentialsProvider = serviceConfiguration.credentialsProvider as? AWSCognitoCredentialsProvider
            return credentialsProvider?.identityProvider.identityProviderManager as? AWSCognitoIdentityUserPool
        }
        
        // MARK: - Initialization
        
        /// Returns a configuration with the provided values.
        public init(credentials: RFCredentials, region: RFRegion) {
            self.credentials = credentials
            self.region = region
        }
        
        // MARK: - AWS Interface
        
        /// Creates and returns a new service configuration with a particular set of credentials.
        private func newServiceConfiguration() -> AWSServiceConfiguration {
            let temporaryConfiguration = AWSServiceConfiguration(region: region.regionType, credentialsProvider: nil)!
            let credentialsProvider = credentials.newCredentialsProvider(with: temporaryConfiguration)
            let serviceConfiguration = AWSServiceConfiguration(region: region.regionType,
                                                               credentialsProvider: credentialsProvider)!
            
            return serviceConfiguration
        }
        
        // MARK: - Codable
        
        private enum CodingKeys: String, CodingKey {
            case credentials = "Credentials"
            case region = "Region"
        }
        
        // MARK: - Equatable
        
        public static func == (lhs: RFContainer.Configuration, rhs: RFContainer.Configuration) -> Bool {
            return lhs.credentials == rhs.credentials && lhs.region == rhs.region
        }
    }
}
