//
//  RFFetchRecordsOperation.swift
//  RFCore
//
//  Created by David Moore on 7/17/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

/// An operation used to retrieve records from RFCore.
open class RFFetchRecordsOperation: RFContainerOperation {
    
    // MARK: - Properties
    
    /// The array of IDs corresponding to the records to fetch.
    open var recordIDs: [RFRecord.ID]?
    
    /// The fields to retrieve for the requested records.
    open var desiredKeys: [String]?
    
    /// The block to execute with progress information for individual records.
    open var perRecordProgressBlock: ((RFRecord.ID, Double) -> Void)?
    
    /// The block to execute when the results of a single record are available.
    open var perRecordCompletionBlock: ((RFRecord?, RFRecord.ID?, Error?) -> Void)?
    
    /// The block to execute after all records are fetched or have received appropriate errors.
    open var fetchRecordsCompletionBlock: (([RFRecord.ID: RFRecord]?, Error?) -> Void)?
    
    /// Queue used for running a number of concurrent fetches.
    internal lazy var fetchQueue = OperationQueue()
    
    // MARK: - Initialization
    
    /// Initializes and returns an operation object configured to fetch the records with the specified IDs.
    public convenience init(recordIDs: [RFRecord.ID]) {
        self.init()
        self.recordIDs = recordIDs
    }
    
    public override init() {
        super.init()
    }
    
    // MARK: - State
    
    open override func start() {
        super.start()
        
        guard !isCancelled, let recordIDs = recordIDs else {
            self.fetchRecordsCompletionBlock?(nil, nil)
            return currentState = .finished
        }
        
        // Update the state.
        currentState = .executing
        
        // Declare a dictionary to contain all of the asset fetch progress.
        let resourceLock = DispatchSemaphore(value: 1)
        var recordsByRecordID = [RFRecord.ID: RFRecord]()
        var assetReferenceByAssetID = [RFAsset.ID: RFAssetReference]()
        var progressByAssetReference = [RFAssetReference: Double]()
        
        // Create an operation to fetch assets in bulk.
        let fetchAssetsOperation = RFFetchAssetsOperation()
        fetchAssetsOperation.setProperties(basedOn: self)
        
        /// Calculates the total progress for all assets being fetched that share the same `parentRecordID`.
        func calculateCumulativeProgressForAssetReferences(relatedTo assetReference: RFAssetReference) -> Double {
            // Retrieve all of thee asset references that are applicable for this parent record.
            let assetReferences = progressByAssetReference.filter { $0.key.parentRecordID == assetReference.parentRecordID }
            
            // Compute the total progress out of the number of the asset references.
            let totalProgress = assetReferences.reduce(0) { $0 + $1.value } / Double(assetReferences.count)
            
            return totalProgress
        }
        
        fetchAssetsOperation.perAssetProgressBlock = { [weak self] assetID, progress in
            guard let strongSelf = self else { return }
            
            if strongSelf.isDatabaseOperation {
                resourceLock.wait()
                // Determine the reference
                if let assetReference = assetReferenceByAssetID[assetID] {
                    // Update the progress for this reference.
                    progressByAssetReference[assetReference] = progress
                    
                    // Compute the total progress and report that instead.
                    let cumulativeProgress = calculateCumulativeProgressForAssetReferences(relatedTo: assetReference)
                    
                    // Report the cumulative progress.
                    strongSelf.perRecordProgressBlock?(assetReference.parentRecordID, cumulativeProgress)
                }
                resourceLock.signal()
            } else {
                strongSelf.perRecordProgressBlock?(RFRecord.ID(recordName: assetID.assetName), progress)
            }
        }
        
        // Handle the per asset completion.
        fetchAssetsOperation.perAssetCompletionBlock = { [weak self] fetchedAsset, assetID, error in
            guard let strongSelf = self else { return }
            
            if let fetchedAsset = fetchedAsset, let assetID = assetID {
                if strongSelf.isDatabaseOperation {
                    resourceLock.wait()
                    guard let assetReference = assetReferenceByAssetID[assetID],
                        let record = recordsByRecordID[assetReference.parentRecordID] else {
                            strongSelf.perRecordCompletionBlock?(nil, nil, CocoaError.error(.coderInvalidValue))
                            return
                    }
                    
                    // Update the progress for this reference.
                    progressByAssetReference[assetReference] = 1
                    
                    // Update the asset.
                    record[assetReference.assetKey] = fetchedAsset
                    
                    // Compute the cumulative progress.
                    let cumulativeProgress = calculateCumulativeProgressForAssetReferences(relatedTo: assetReference)
                    
                    // The entire record is complete at this point.
                    if cumulativeProgress >= 1 {
                        strongSelf.perRecordCompletionBlock?(record, record.recordID, nil)
                    }
                    resourceLock.signal()
                } else {
                    strongSelf.perRecordCompletionBlock?(RFRecord(asset: fetchedAsset), RFRecord.ID(recordName: assetID.assetName), nil)
                }
            } else {
                strongSelf.perRecordCompletionBlock?(nil, nil, error)
            }
        }
        
        // Handle the bulk return.
        fetchAssetsOperation.fetchAssetsCompletionBlock = { [weak self] assetsByAssetID, error in
            guard let strongSelf = self else { return }
            
            // Handle the database operation differently.
            if strongSelf.isDatabaseOperation {
                // Call completion and update state.
                strongSelf.fetchRecordsCompletionBlock?(recordsByRecordID, error)
                strongSelf.currentState = .finished
            } else {
                // Convert the assets into records.
                let recordsByRecordID = assetsByAssetID?.reduce(into: [RFRecord.ID: RFRecord]()) { recordsByRecordID, pair in
                    let record = RFRecord(asset: pair.value)
                    recordsByRecordID[record.recordID] = record
                }
                
                // Call completion and update state.
                strongSelf.fetchRecordsCompletionBlock?(recordsByRecordID, error)
                strongSelf.currentState = .finished
            }
        }
        
        if isDatabaseOperation {
            // Configure an operation to fetch records using a database.
            let fetchOperation = RFFetchRecordsDatabaseOperation(recordIDs: recordIDs)
            fetchOperation.setProperties(basedOn: self)
            fetchOperation.desiredKeys = desiredKeys
            fetchOperation.perRecordProgressBlock = perRecordProgressBlock
            fetchOperation.perRecordCompletionBlock = perRecordCompletionBlock
            
            // Handle the completion.
            fetchOperation.fetchRecordsCompletionBlock = { [weak self] _recordsByRecordID, error in
                guard let strongSelf = self else { return }
                
                guard let _recordsByRecordID = _recordsByRecordID else {
                    strongSelf.fetchRecordsCompletionBlock?(nil, error)
                    return strongSelf.currentState = .finished
                }
                
                // Maintain a reference to the records so they may be updated later.
                recordsByRecordID = _recordsByRecordID
                
                let assetReferencesByRecordID = recordsByRecordID.mapValues { $0.valueStorage.map.values.compactMap { $0 as? RFAssetReference }}
                
                // Map the asset references.
                let assetReferences = Array(recordsByRecordID.values.map { $0.valueStorage.map.values.lazy.compactMap { $0 as? RFAssetReference }}.joined())
                
                // Initialize required values of the dictionaries for later use.
                for assetReference in assetReferences {
                    assetReferenceByAssetID[assetReference.assetID] = assetReference
                    progressByAssetReference[assetReference] = 0
                }
                
                // Report the completion of any completed record IDs.
                let completedRecordIDs = Array(assetReferencesByRecordID.filter { $1.isEmpty }.keys)
                for completedRecordID in completedRecordIDs {
                    strongSelf.perRecordCompletionBlock?(recordsByRecordID[completedRecordID], completedRecordID, nil)
                }
                
                if assetReferences.isEmpty {
                    // There is nothing left to fetch.
                    strongSelf.fetchRecordsCompletionBlock?(recordsByRecordID, error)
                    strongSelf.currentState = .finished
                } else {
                    // Configure the fetch operation to fetch the references assets.
                    fetchAssetsOperation.assetIDs = assetReferences.map { $0.assetID }
                    
                    //  Submit the fetch assets operation to the queue.
                    strongSelf.fetchQueue.addOperation(fetchAssetsOperation)
                }
            }
            
            // Start running the database fetch.
            fetchQueue.addOperation(fetchOperation)
        } else {
            fetchAssetsOperation.assetIDs = recordIDs.map { RFAsset.ID(assetName: $0.recordName) }
            fetchQueue.addOperation(fetchAssetsOperation)
        }
    }
    
    open override func cancel() {
        super.cancel()
        
        // Use the queue to cancel everything.
        fetchQueue.cancelAllOperations()
        currentState = .finished
    }
}
