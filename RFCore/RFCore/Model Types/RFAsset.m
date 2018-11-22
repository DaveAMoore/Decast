//
//  RFAsset.m
//  RFCore
//
//  Created by David Moore on 8/6/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#import "RFAsset.h"
#import "RFAsset-Internal.h"

NSString *const RFEntityTagAttributeKey = @"ca.mooredev.RFCore.RFEntityTagAttribute";

@implementation RFAssetID
@synthesize assetName=_assetName;

- (instancetype)initWithAssetName:(NSString *)assetName {
    self = [super init];
    if (self) {
        _assetName = assetName;
    }
    return self;
}

- (BOOL)isFolder {
    return [self.assetName characterAtIndex:MAX(self.assetName.length - 1, 0)] == '/';
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if (![super isKindOfClass:[RFAssetID class]]) {
        return NO;
    } else {
        return [self isEqualToAssetID:(RFAssetID *)other];
    }
}

- (BOOL)isEqualToAssetID:(RFAssetID *)other {
    return [self.assetName isEqualToString:other.assetName];
}

- (NSUInteger)hash {
    return [self.assetName hash];
}

@end

@implementation RFAsset
@synthesize fileURL=_fileURL, contentType, attributes=_attributes, entityTag, modificationDate, assetID;

- (instancetype)initWithFileURL:(NSURL *)fileURL {
    self = [super init];
    if (self) {
        _fileURL = fileURL;
    }
    return self;
}

- (RFAssetAttributes *)attributes {
    if (!_attributes) {
        _attributes = [[RFAssetAttributes alloc] initWithFileURL:self.fileURL];
    }
    
    return _attributes;
}

- (NSString *)contentType {
    return [self.fileURL pathExtension];
}

- (NSDate *)modificationDate {
    NSError *error = NULL;
    NSDictionary<NSFileAttributeKey, id> *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[self.fileURL path]
                                                                                                        error:&error];
    
    if (error) {
        return NULL;
    }
    
    id modificationDate = [attributes valueForKey:NSFileModificationDate];
    
    if (modificationDate) {
        return modificationDate;
    } else {
        return NULL;
    }
}

- (void)setModificationDate:(NSDate *)modificationDate {
    [[NSFileManager defaultManager] setAttributes:@{ NSFileModificationDate: modificationDate }
                                     ofItemAtPath:[self.fileURL path]
                                            error:NULL];
}

- (NSString *)entityTag {
    return [self.attributes attributeForKey:RFEntityTagAttributeKey];
}

- (void)setEntityTag:(NSString *)entityTag {
    [self.attributes setAttribute:entityTag forKey:RFEntityTagAttributeKey];
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)other {
    if (self == other) {
        return YES;
    } else if (![other isKindOfClass:[RFAsset class]]) {
        return NO;
    } else {
        return [self isEqualToAsset:(RFAsset *)other];
    }
}

- (BOOL)isEqualToAsset:(RFAsset *)other {
    return [other.fileURL isEqual:other.fileURL];
}

- (NSUInteger)hash {
    return [self.fileURL hash];
}

@end
