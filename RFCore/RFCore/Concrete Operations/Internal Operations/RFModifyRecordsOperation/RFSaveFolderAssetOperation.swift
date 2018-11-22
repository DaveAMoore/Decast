//
//  RFSaveFolderAssetOperation.swift
//  RFCore
//
//  Created by David Moore on 7/31/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation
import AWSS3
import RFAssetInternal

/// An operation that can save a single asset that represents a folder.
internal class RFSaveFolderAssetOperation: RFContainerOperation {
    
    // MARK: - Properties
    
    /// The asset to save to the database.
    open var asset: RFAsset?
    
    /// The block to execute after the status of all changes is known.
    open var saveAssetCompletionBlock: ((RFAsset?, Error?) -> Void)?
    
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
        
        // Ensure the asset is a folder.
        precondition(asset.assetID.isFolder, "Expected 'asset.assetID.isFolder' to be true")
        
        // Configure the folder creation request.
        let createFolderRequest = AWSS3PutObjectRequest()!
        createFolderRequest.bucket = operationalContainer.containerID
        createFolderRequest.key = asset.assetID.assetName
        
        // Unwrap the modification date
        let modificationDate = asset.modificationDate ?? Date()
        
        // Create a date formatter to convert the date to a string.
        let dateFormatter = ISO8601DateFormatter()
        let dateString = dateFormatter.string(from: modificationDate)
        
        // Register the value.
        createFolderRequest.metadata = [RFRecord.MetadataKeys.modificationDate: dateString]
        
        // Start creating the folder.
        let createFolderTask = operationalContainer.storageService.putObject(createFolderRequest)
        
        // Update the state.
        currentState = .executing
        
        createFolderTask.continueWith { [weak self] task -> Any? in
            defer {
                self?.currentState = .finished
            }
            
            // Update the entity tag.
            asset.entityTag = task.result?.eTag
            
            // Call the completion block.
            self?.saveAssetCompletionBlock?(asset, task.error)
            
            return nil
        }
    }
    
    open override func cancel() {
        super.cancel()
    }
}
