//
//  RFFetchAssetOperation.swift
//  RFCore
//
//  Created by David Moore on 7/21/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation
import AWSS3

/// An operation used to retrieve a single asset from RFCore.
internal class RFFetchAssetOperation: RFContainerOperation {
    
    // MARK: - Properties
    
    /// The IDs corresponding to the record to fetch.
    internal var assetID: RFAsset.ID?
    
    /// Transfer utility to use for fetching the record. Default value is derived through accessing `operationalContainer.transferUtility`.
    internal var transferUtility: AWSS3TransferUtility?
    
    /// The block to execute with progress information for the record.
    internal var progressBlock: ((Double) -> Void)?
    
    /// The block to execute after the record has been fetched or an error has occurred.
    internal var fetchAssetCompletionBlock: ((RFAsset?, Error?) -> Void)?
    
    /// Current download task that is executing.
    private var currentTask: AWSS3TransferUtilityDownloadTask?
    
    // MARK: - Initialization
    
    /// Initializes and returns an operation object configured to fetch a single record with the specified ID.
    internal convenience init(assetID: RFAsset.ID) {
        self.init()
        self.assetID = assetID
    }
    
    internal override init() {
        super.init()
    }
    
    // MARK: - State
    
    internal override func start() {
        super.start()
        
        guard !isCancelled, let assetID = assetID else {
            self.fetchAssetCompletionBlock?(nil, nil)
            return currentState = .finished
        }
        
        // Update the state.
        currentState = .executing
        
        // Create a temporary URL.
        let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        // If this is a directory we do no need to download it, but instead simply create it.
        guard !assetID.isFolder else {
            // Create the asset.
            let asset = RFAsset(fileURL: temporaryURL)
            
            do {
                // Create the directory and call completion.
                try FileManager.default.createDirectory(at: asset.fileURL, withIntermediateDirectories: true, attributes: nil)
                fetchAssetCompletionBlock?(asset, nil)
            } catch {
                // Ignore a file exists error, as it doesn't necessarily influence us.
                if let error = error as? CocoaError, error.code == .fileWriteFileExists {
                    fetchAssetCompletionBlock?(asset, nil)
                } else {
                    fetchAssetCompletionBlock?(asset, error)
                }
            }
            
            // Update the state.
            currentState = .finished
            
            return
        }
        
        // Unwrap the transfer utility.
        let transferUtility = self.transferUtility ?? operationalContainer.transferUtility
        
        // Create a fetch expression to receive progress updates.
        let fetchExpression = AWSS3TransferUtilityDownloadExpression()
        fetchExpression.progressBlock = { [weak self] task, progress in
            self?.progressBlock?(progress.fractionCompleted)
        }
        
        // Handle the completion state of the download.
        let completionBlock: AWSS3TransferUtilityDownloadCompletionHandlerBlock = { [weak self] task, fileURL, _, error in
            guard let strongSelf = self else { return }
            
            defer {
                strongSelf.currentTask = nil
                strongSelf.currentState = .finished
            }
            
            guard !strongSelf.isCancelled else {
                strongSelf.fetchAssetCompletionBlock?(nil, nil)
                return
            }
            
            // Unwrap the file URL.
            guard let fileURL = fileURL else {
                strongSelf.fetchAssetCompletionBlock?(nil, error)
                return
            }
            
            // Create an asset.
            let asset = RFAsset(fileURL: fileURL)
            asset.assetID = assetID
            
            // Update the asset's entity tag.
            asset.entityTag = task.response?.entityTag
            
            // Retrieve the modification date from the metadata.
            if let dateString = task.response?.allHeaderFields[RFRecord.MetadataKeys.modificationDate] as? String {
                // Decode the date.
                let dateFormatter = ISO8601DateFormatter()
                let modificationDate = dateFormatter.date(from: dateString)
                
                // Apply it to the record.
                asset.modificationDate = modificationDate
            }
            
            // Call completion.
            strongSelf.fetchAssetCompletionBlock?(asset, nil)
        }
        
        // Start the download.
        let downloadTask = transferUtility.download(to: temporaryURL,
                                                    bucket: operationalContainer.containerID,
                                                    key: assetID.assetName, expression: fetchExpression,
                                                    completionHandler: completionBlock)
        
        // Retrieve the current task.
        self.currentTask = downloadTask.result
    }
    
    internal override func cancel() {
        super.cancel()
        
        // Cancel the task.
        currentTask?.cancel()
        currentTask = nil
        currentState = .finished
    }
}
