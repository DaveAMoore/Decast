//
//  RFSaveAssetOperation.swift
//  RFCore
//
//  Created by David Moore on 7/27/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation
import AWSS3
import RFAssetInternal

/// Saves a single asset to S3 using either a single or multi-part upload.
internal class RFSaveAssetOperation: RFContainerOperation {
    
    // MARK: - Properties
    
    /// The asset to save to the database.
    open var asset: RFAsset?
    
    /// Transfer utility to use for saving the asset. Default value is obtained through accessing `operationalContainer.transferUtility`.
    internal var transferUtility: AWSS3TransferUtility?
    
    /// The block to execute with progress information for an individual asset.
    open var progressBlock: ((RFAsset, Double) -> Void)?
    
    /// The block to execute after the status of all changes is known.
    open var saveAssetCompletionBlock: ((RFAsset?, Error?) -> Void)?
    
    /// Save queue to use for saving operations.
    internal lazy var saveQueue: OperationQueue = OperationQueue()
    
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
        
        // Retrieve the attributes of the file in order to determine its size.
        let attributes = try? FileManager.default.attributesOfItem(atPath: asset.fileURL.path)
        let size = (attributes?[.size] as? NSNumber)?.doubleValue ?? 0
        
        let completionBlock: ((RFAsset?, Error?) -> Void) = { [weak self] asset, error in
            // asset?.entityTag = record?.entityTag
            self?.saveAssetCompletionBlock?(asset, error)
            self?.currentState = .finished
        }
        
        // Use a special operation for creating a folder record.
        // Use a single-part upload if the size of the file either cannot be determined, or is less than 256 MB.
        // Use multi-part for anything larger.
        if asset.assetID.isFolder {
            let saveFolderOperation = RFSaveFolderAssetOperation(asset: asset)
            saveFolderOperation.setProperties(basedOn: self)
            saveFolderOperation.saveAssetCompletionBlock = completionBlock
            
            currentState = .executing
            saveQueue.addOperation(saveFolderOperation)
        } else if size < 2.56e8 {
            let singlePartOperation = RFSinglePartSaveAssetOperation(asset: asset)
            singlePartOperation.setProperties(basedOn: self)
            singlePartOperation.transferUtility = transferUtility
            singlePartOperation.progressBlock = progressBlock
            singlePartOperation.saveAssetCompletionBlock = completionBlock
            
            currentState = .executing
            saveQueue.addOperation(singlePartOperation)
        } else {
            let multiPartOperation = RFMultiPartSaveAssetOperation(asset: asset)
            multiPartOperation.setProperties(basedOn: self)
            multiPartOperation.transferUtility = transferUtility
            multiPartOperation.progressBlock = progressBlock
            multiPartOperation.saveAssetCompletionBlock = completionBlock
            
            currentState = .executing
            saveQueue.addOperation(multiPartOperation)
        }
        
    }
    
    open override func cancel() {
        super.cancel()
        
        saveQueue.cancelAllOperations()
        currentState = .finished
    }
}
