//
//  RFContainer.swift
//  RFCore
//
//  Created by David Moore on 7/17/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation
import AWSS3
import AWSSNS
import AWSDynamoDB

/// A conduit for accessing and performing operations on the data of an app container.
open class RFContainer: NSObject {
    
    // MARK: - Constants
    
    /// Key representing the default container identifier for the `default` container.
    public static let DefaultContainerIDKey = "RFDefaultContainerID"
    
    /// Key representing the default container identifier for the `default` container to use for debug builds.
    public static let DebugContainerIDKey = "RFDebugContainerID"
    
    /// Key representing the default container's database identifier for the `default` container.
    public static let DefaultDatabaseIDKey = "RFDefaultDatabaseID"
    
    /// Key representing the default container's database identifier for the `default` container to use for debug builds.
    public static let DebugDatabaseIDKey = "RFDebugDatabaseID"
    
    /// Key representing the default subscription zone identifier for the `default` container.
    public static let DefaultSubscriptionZoneIDKey = "RFDefaultSubscriptionZoneID"
    
    /// Key representing the default subscription zone identifier for the `default` container to use for debug builds..
    public static let DebugSubscriptionZoneIDKey = "RFDebugSubscriptionZoneID"
    
    /// Key representing the default container configuration for the `default` container.
    public static let DefaultConfigurationKey = "RFDefaultContainerConfiguration"
    
    // MARK: - Properties
    
    /// Convenience method that uses the calling process' 'RFContainerIdentifier' as the container identifier.
    public static private(set) var `default`: RFContainer = {
        let container = RFContainer(bundle: .main)
        return container
    }()
    
    /// The configuration of the container.
    public let configuration: Configuration
    
    /// `S3` service associated with the configuration and other details specified.
    internal lazy var storageService: AWSS3 = {
        return newS3Service()
    }()
    
    /// `SNS` service associated with the container.
    internal lazy var subscriptionService: AWSSNS = {
        return newSNSService()
    }()
    
    /// `DynamoDB` service associated with the container.
    internal lazy var databaseService: AWSDynamoDB = {
        return newDatabaseService()
    }()
    
    /// S3 transfer utility with a custom configuration that is defined by `configuration`.
    internal lazy var transferUtility: AWSS3TransferUtility = {
        return newTransferUtility()
    }()
    
    /// The string that identifies the app’s container.
    public let containerID: String
    
    /// The string that uniquely identifies the container's database.
    public let databaseID: String?
    
    /// The string that identifies the app's subscription zone; equivalent to the platform application ARN.
    open var subscriptionZoneID: String?
    
    /// Internal subscription zone identifier to be used unconditionally.
    internal var operationalSubscriptionZoneID: String {
        // Unwrap the subscription zone ID.
        guard let subscriptionZoneID = subscriptionZoneID else { preconditionFailure("'subscriptionZoneID' was nil") }
        return subscriptionZoneID
    }
    
    /// Token used to observe changes related to the default queue.
    private var defaultQueueObservationToken: NSObjectProtocol?
    
    /// Queue designated to be used for all operations.
    private let defaultQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .default
        return queue
    }()
    
    /// Operations that are currently running on the default queue.
    @objc dynamic open var operations: [RFOperation] {
        return defaultQueue.operations.compactMap { $0 as? RFOperation }
    }
    
    // MARK: - Initialization
    
    /// Returns the container object associated with the specified identifier.
    public init(configuration: Configuration, containerID: String, databaseID: String? = nil) {
        self.configuration = configuration
        self.containerID = containerID
        self.databaseID = databaseID
        super.init()
        
        // Observe the operations property of the queue in order to make 'operations' function properly.
        defaultQueueObservationToken = defaultQueue.observe(\.operations, options: .prior) { [weak self] queue, change in
            if change.isPrior {
                self?.willChangeValue(for: \RFContainer.operations)
            } else {
                self?.didChangeValue(for: \RFContainer.operations)
            }
        }
    }
    
    /// Returns the container object associated with the bundle.
    public convenience init(bundle: Bundle) {
        let infoDictionary = bundle.infoDictionary
        
        // Retrieve the default identifier from the Info.plist.
        guard let configurationDictionary = infoDictionary?[RFContainer.DefaultConfigurationKey] as? [String: Any] else {
            preconditionFailure("RFDefaultContainerConfiguration not found in Info.plist")
        }
        
        #if DEBUG
        guard let containerID = (infoDictionary?[RFContainer.DebugContainerIDKey] as? String) ?? (infoDictionary?[RFContainer.DefaultContainerIDKey] as? String) else {
            preconditionFailure("RFDebugContainerID or RFDefaultContainerID not found in Info.plist")
        }
        #else
        guard let containerID = infoDictionary?[RFContainer.DefaultContainerIDKey] as? String else {
            preconditionFailure("RFDefaultContainerID not found in Info.plist")
        }
        #endif
        
        // Retrieve the other IDs
        #if DEBUG
        let databaseID = (infoDictionary?[RFContainer.DebugDatabaseIDKey] as? String) ?? (infoDictionary?[RFContainer.DefaultDatabaseIDKey] as? String)
        let subscriptionZoneID = (infoDictionary?[RFContainer.DebugSubscriptionZoneIDKey] as? String) ?? (infoDictionary?[RFContainer.DefaultSubscriptionZoneIDKey] as? String)
        #else
        let databaseID = infoDictionary?[RFContainer.DefaultDatabaseIDKey] as? String
        let subscriptionZoneID = infoDictionary?[RFContainer.DefaultSubscriptionZoneIDKey] as? String
        #endif
        
        // Decode the configuration from the PLIST.
        let decoder = DictionaryDecoder()
        let configuration = try! decoder.decode(Configuration.self, from: configurationDictionary)
        
        // Init the container with the default values.
        self.init(configuration: configuration, containerID: containerID, databaseID: databaseID)
        self.subscriptionZoneID = subscriptionZoneID
    }
    
    // MARK: - Equatability
    
    /// Returns if the two objects are equal to one another.
    open override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? RFContainer else { return false }
        return configuration == rhs.configuration && storageService == rhs.storageService && transferUtility == rhs.transferUtility && containerID == rhs.containerID && defaultQueue == rhs.defaultQueue && defaultQueue == rhs.defaultQueue
    }
    
    // MARK: - AWS Interface
    
    /// Creates and returns a new service for interacting with S3.
    private func newS3Service() -> AWSS3 {
        // Create a new service configuration and register it with S3.
        let s3Key = "ca.mooredev.RFCore.RFContainer.AWSS3-\(UUID().uuidString)"
        AWSS3.register(with: configuration.serviceConfiguration, forKey: s3Key)
        
        // Retrieve the registered service.
        let s3Service = AWSS3.s3(forKey: s3Key)
        
        return s3Service
    }
    
    /// Creates and returns a new service for interacting with SNS.
    private func newSNSService() -> AWSSNS {
        // Create a new service configuration and register it with SNS.
        let snsKey = "ca.mooredev.RFCore.RFContainer.AWSSNS-\(UUID().uuidString)"
        AWSSNS.register(with: configuration.serviceConfiguration, forKey: snsKey)
        
        // Retrieve the registered service.
        let snsService = AWSSNS(forKey: snsKey)
        
        return snsService
    }
    
    /// Creates and returns a new service for interacting with databases.
    private func newDatabaseService() -> AWSDynamoDB {
        // Create a new service configuration and register it with DynamoDB.
        let databaseKey = "ca.mooredev.RFCore.RFContainer.AWSDynamoDB-\(UUID().uuidString)"
        AWSDynamoDB.register(with: configuration.serviceConfiguration, forKey: databaseKey)
        
        // Retrieve the service.
        let databaseService = AWSDynamoDB(forKey: databaseKey)
        
        return databaseService
    }
    
    /// Creates and returns a new transfer utility to perform transfers with S3.
    private func newTransferUtility() -> AWSS3TransferUtility {
        // Specify the configuration.
        let transferUtilityConfiguration = AWSS3TransferUtilityConfiguration()
        transferUtilityConfiguration.bucket = containerID
        transferUtilityConfiguration.retryLimit = 25
        
        // Register the configuration.
        let transferUtilityKey = "ca.mooredev.RFCore.RFContainer.AWSS3TransferUtility"
        AWSS3TransferUtility.register(with: configuration.serviceConfiguration,
                                      transferUtilityConfiguration: transferUtilityConfiguration, forKey: transferUtilityKey)
        
        // Retrieve the transfer utility using the key.
        let transferUtility = AWSS3TransferUtility.s3TransferUtility(forKey: transferUtilityKey)
        
        return transferUtility
    }
    
    // MARK: - Executing Operations
    
    /// Executes the specified operation asynchronously against the current container.
    ///
    /// - Parameter operation: The operation object to execute. You must configure the operation object with any dependencies and completion handlers before calling this method. If this parameter is nil, the method does nothing.
    open func add(_ operation: RFContainerOperation) {
        operation.container = self
        defaultQueue.addOperation(operation)
    }
    
    // MARK: - Convenience Methods
    
    /// Searches the container asynchronously for records that match the query parameters.
    ///
    /// - Parameters:
    ///   - query: The query object containing the parameters for the search. This method throws an exception if this parameter is nil. For information about how to construct queries, see `RFQuery`.
    ///   - completionHandler: The block to execute with the search results. Your block must be capable of running on any thread of the app and must take the following parameters:
    ///     - results: An array containing zero or more `RFRecord` objects. The returned records correspond to the records that match the parameters of the query.
    ///     - error: An error object, or nil if the query was completed successfully. Use the information in the error object to determine whether a problem has a workaround.
    open func perform(_ query: RFQuery, completionHandler: @escaping (([RFRecord]?, Error?) -> Void)) {
        let queryOperation = RFQueryOperation(query: query)
        queryOperation.container = self
        queryOperation.qualityOfService = .userInitiated
        
        // Assign a block to process the results.
        queryOperation.queryCompletionBlock = { records, cursor, error in
            completionHandler(records, error)
        }
        
        // Add the query operation to the queue for running.
        defaultQueue.addOperation(queryOperation)
    }
    
    /// Fetches one record asynchronously, with a low priority, from the current container.
    ///
    /// - Parameters:
    ///   - recordID: The ID of the record you want to fetch. This method throws an exception if this parameter is nil.
    ///   - completionHandler: The block to execute with the results. Your block must be capable of running on any thread of the app and must take the following parameters:
    ///     - record: The requested record object. If no such record is found, this parameter is nil.
    ///     - error: An error object, or nil if the record was fetched successfully. Use the information in the error object to determine whether a problem has a workaround.
    open func fetch(withRecordID recordID: RFRecord.ID, completionHandler: @escaping ((RFRecord?, Error?) -> Void)) {
        let fetchOperation = RFFetchRecordsOperation(recordIDs: [recordID])
        fetchOperation.container = self
        fetchOperation.qualityOfService = .userInteractive
        
        // Assign a block to handle the results.
        fetchOperation.fetchRecordsCompletionBlock = { fetchedRecordsByID, error in
            completionHandler(fetchedRecordsByID?.values.first, error)
        }
        
        // Add the fetch operation to the internal queue.
        defaultQueue.addOperation(fetchOperation)
    }
    
    /// Saves one record asynchronously, with a low priority, to the current database, if the record has never been saved or if it is newer than the version on the server.
    ///
    /// - Parameters:
    ///   - record: The record to save. This method throws an exception if this parameter is nil.
    ///   - completionHandler: The block to execute with the results. Your block must be capable of running on any thread of the app and must take the following parameters:
    ///     - record: The record object you attempted to save.
    ///     - error: An error object, or nil if the record was saved successfully. Use the information in the error object to determine whether a problem has a workaround.
    open func save(_ record: RFRecord, completionHandler: @escaping ((RFRecord?, Error?) -> Void)) {
        let saveOperation = RFModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        saveOperation.container = self
        saveOperation.qualityOfService = .userInitiated
        
        // Handle the result.
        saveOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
            completionHandler(savedRecords?.first, error)
        }
        
        // Start executing the operation.
        defaultQueue.addOperation(saveOperation)
    }
    
    /// Deletes the specified record asynchronously, with a low priority, from the current database.
    ///
    /// - Parameters:
    ///   - recordID: The ID of the record you want to delete. This method throws an exception if this parameter is nil.
    ///   - completionHandler: The block to execute with the results. Your block must be capable of running on any thread of the app and must take the following parameters:
    ///     - recordID: The ID of the record you attempted to delete.
    ///     - error: An error object, or nil if the record was deleted successfully. Use the information in the error object to determine whether a problem has a workaround.
    open func delete(withRecordID recordID: RFRecord.ID, completionHandler: @escaping ((RFRecord.ID?, Error?) -> Void)) {
        let deleteOperation = RFModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [recordID])
        deleteOperation.container = self
        deleteOperation.qualityOfService = .userInitiated
        
        // Handle the completion.
        deleteOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
            completionHandler(deletedRecordIDs?.first, error)
        }
        
        // Begin executing the operation.
        defaultQueue.addOperation(deleteOperation)
    }
    
    /// Saves one subscription object asynchronously, with a low priority, to the current container.
    ///
    /// - Parameters:
    ///   - subscription: The subscription object you want to save to the container. This method throws an exception if this parameter is nil.
    ///   - completionHandler: The block to execute with the results. Your block must be capable of running on any thread of the app and must take the following parameters:
    ///     - subscription: The subscription object you attempted to save.
    ///     - error: An error object, or nil if the subscription was saved successfully. Use the information in the error object to determine whether a problem has a workaround.
    open func save(_ subscription: RFSubscription, completionHandler: @escaping ((RFSubscription?, Error?) -> Void)) {
        let saveOperation = RFModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)
        saveOperation.container = self
        saveOperation.qualityOfService = .userInitiated
        
        // Handle the completion.
        saveOperation.modifySubscriptionsCompletionBlock = { savedSubscriptions, deletedSubscriptionIDs, error in
            completionHandler(savedSubscriptions?.first, error)
        }
        
        // Start saving the subscription.
        defaultQueue.addOperation(saveOperation)
    }
    
    /// Saves one subscription object asynchronously, with a low priority, to the current container.
    ///
    /// - Parameters:
    ///   - subscription: The subscription object you want to save to the container. This method throws an exception if this parameter is nil.
    ///   - completionHandler: The block to execute with the results. Your block must be capable of running on any thread of the app and must take the following parameters:
    ///     - subscription: The subscription object you attempted to save.
    ///     - error: An error object, or nil if the subscription was saved successfully. Use the information in the error object to determine whether a problem has a workaround.
    open func delete(withSubscriptionID subscriptionID: RFSubscription.ID, completionHandler: @escaping ((RFSubscription.ID?, Error?) -> Void)) {
        let deleteOperation = RFModifySubscriptionsOperation(subscriptionsToSave: nil, subscriptionIDsToDelete: [subscriptionID])
        deleteOperation.container = self
        deleteOperation.qualityOfService = .userInitiated
        
        // Handle the completion.
        deleteOperation.modifySubscriptionsCompletionBlock = { savedSubscriptions, deletedSubscriptionIDs, error in
            completionHandler(deletedSubscriptionIDs?.first, error)
        }
        
        // Start deleting the subscription.
        defaultQueue.addOperation(deleteOperation)
    }
}
