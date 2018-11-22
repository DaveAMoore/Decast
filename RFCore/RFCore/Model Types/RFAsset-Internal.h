//
//  RFAsset-Internal.h
//  RFCore
//
//  Created by David Moore on 8/28/18.
//

#import <Foundation/Foundation.h>
#import "RFAsset.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(RFAsset.ID)
@interface RFAssetID : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/** Creates a new asset ID with `assetName`. */
- (instancetype)initWithAssetName:(NSString *)assetName NS_DESIGNATED_INITIALIZER;

/** The unique name of the asset. */
@property (nonatomic, readonly, strong) NSString *assetName;

/**  boolean value indicating if the asset is a folder. */
@property (readonly) BOOL isFolder;

@end

@interface RFAsset ()

/** Unique identifier for the asset to be used when saving. */
@property (nonatomic, readwrite) RFAssetID *assetID;

@end

NS_ASSUME_NONNULL_END
