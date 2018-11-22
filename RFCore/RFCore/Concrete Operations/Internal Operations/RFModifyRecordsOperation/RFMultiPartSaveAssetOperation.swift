//
//  RFMultiPartSaveAssetOperation.swift
//  RFCore
//
//  Created by David Moore on 7/29/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation
import AWSS3
import RFAssetInternal

/// An operation that uploads a single `RFAsset` using multiple segments of data.
internal class RFMultiPartSaveAssetOperation: RFContainerOperation {

    // MARK: - Properties
    
    /// The asset to save to the database.
    open var asset: RFAsset?
    
    /// Transfer utility to use for saving the record. Default value is derived through accessing `operationalContainer.transferUtility`.
    internal var transferUtility: AWSS3TransferUtility?
    
    /// The block to execute with progress information for an individual asset.
    open var progressBlock: ((RFAsset, Double) -> Void)?
    
    /// The block to execute after the status of all changes is known.
    open var saveAssetCompletionBlock: ((RFAsset?, Error?) -> Void)?
    
    /// Current upload task that is executing.
    private var currentTask: AWSS3TransferUtilityMultiPartUploadTask?
    
    // MARK: - Initialization
    
    /// Initializes and returns an operation object.
    public convenience init(asset: RFAsset?) {
        self.init()
        self.asset = asset
    }
    
    /// Initializes and returns an operation object.
    public override init() {
        super.init()
    }
    
    // MARK: - State
    
    open override func start() {
        super.start()
        
        guard !isCancelled, let asset = asset else {
            self.saveAssetCompletionBlock?(nil, nil)
            return currentState = .finished
        }
        
        // Unwrap the transfer utility.
        let transferUtility = self.transferUtility ?? operationalContainer.transferUtility
        
        // Configure an upload expression to handle progress updates.
        let uploadExpression = AWSS3TransferUtilityMultiPartUploadExpression()
        uploadExpression.progressBlock = { [weak self] task, progress in
            self?.progressBlock?(asset, progress.fractionCompleted)
        }
        
        // Unwrap the modification date
        let modificationDate = asset.modificationDate ?? Date()
        
        // Create a date formatter to convert the date to a string.
        let dateFormatter = ISO8601DateFormatter()
        let dateString = dateFormatter.string(from: modificationDate)
        
        // Register the value.
        uploadExpression.setValue(dateString, forRequestHeader: RFRecord.MetadataKeys.modificationDate)
        
        // Create a completion handler.
        let completionBlock: AWSS3TransferUtilityMultiPartUploadCompletionHandlerBlock = { [weak self] task, error in
            guard let strongSelf = self else { return }
            
            defer {
                strongSelf.currentState = .finished
                strongSelf.currentTask = nil
            }
            
            guard !strongSelf.isCancelled else {
                strongSelf.saveAssetCompletionBlock?(asset, nil)
                return
            }
            
            if let error = error {
                strongSelf.saveAssetCompletionBlock?(asset, error)
            } else {
                asset.entityTag = task.eTag
                strongSelf.saveAssetCompletionBlock?(asset, nil)
            }
        }
        
        // Update the state.
        currentState = .executing
        
        // Start the upload.
        let uploadTask = transferUtility.uploadUsingMultiPart(fileURL: asset.fileURL,
                                                              bucket: operationalContainer.containerID,
                                                              key: asset.assetID.assetName, contentType: asset.contentType,
                                                              expression: uploadExpression, completionHandler: completionBlock)
        
        // Retrieve the current task.
        self.currentTask = uploadTask.result
    }
    
    open override func cancel() {
        super.cancel()
        
        // Cancel the upload.
        currentTask?.cancel()
        currentTask = nil
        currentState = .finished
    }
}
