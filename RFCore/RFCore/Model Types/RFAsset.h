//
//  RFAsset.h
//  RFCore
//
//  Created by David Moore on 8/6/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFAssetAttributes.h"

NS_ASSUME_NONNULL_BEGIN

@interface RFAsset : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/** Initialize an asset to be saved with the content at the given file URL */
- (instancetype)initWithFileURL:(NSURL *)fileURL NS_DESIGNATED_INITIALIZER;

/** Local file URL where fetched records are cached and saved records originate from. */
@property (nonatomic, readonly, copy) NSURL *fileURL;

/** Content (MIME) type of the file referenced by the asset. */
@property (nonatomic, readonly, copy) NSString *contentType;

/** Modification date of the file as it stands on disk. */
@property (nullable, nonatomic, readwrite) NSDate *modificationDate;

/** Identifier assigned by the server for a particular file referenced by an asset. */
@property (nullable, nonatomic, readwrite) NSString *entityTag;

/** Set of attributes pertaining to the file referenced by the receiver. */
@property (nonatomic, readonly, copy) RFAssetAttributes *attributes;

@end

NS_ASSUME_NONNULL_END
