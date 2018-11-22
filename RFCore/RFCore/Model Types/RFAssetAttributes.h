//
//  RFAssetAttributes.h
//  RFCore
//
//  Created by David Moore on 8/6/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(RFAsset.Attributes)
@interface RFAssetAttributes : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/** Initialize an asset to be saved with the content at the given file URL */
- (instancetype)initWithFileURL:(NSURL *)fileURL NS_DESIGNATED_INITIALIZER;

/** Local file URL where fetched records are cached and saved records originate from. */
@property (nonatomic, readonly, copy) NSURL *fileURL;

/** Collection of the attribute keys associated with the file. */
@property (nullable, nonatomic, readonly, copy) NSArray<NSString *> *keys;

/** Returns a collection of the attribute keys associated with the file. */
// - (nullable NSArray<NSString *> *)attributeKeys;

/** Returns the string value for the file that is stored under a particular key, if there is a value. */
- (nullable NSString *)attributeForKey:(NSString *)key;

/**
 Sets a particular attribute to a string value under a specific key.

 @param aString Attribute value that will be stored as extended metadata in the file.
 @param key Name the extended attribute will be stored in the file as.
 */
- (void)setAttribute:(nullable NSString *)aString forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
