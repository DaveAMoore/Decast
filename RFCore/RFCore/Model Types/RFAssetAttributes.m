//
//  RFAssetAttributes.m
//  RFCore
//
//  Created by David Moore on 8/6/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#import "RFAssetAttributes.h"
#include <sys/xattr.h>

@implementation RFAssetAttributes
@synthesize fileURL=_fileURL;

- (instancetype)initWithFileURL:(NSURL *)fileURL {
    self = [super init];
    if (self) {
        _fileURL = fileURL;
    }
    return self;
}

- (NSArray<NSString *> *)keys {
    // Get the C-String path of the file.
    const char *path = [_fileURL fileSystemRepresentation];
    
    // Determine the size of the attribute names.
    ssize_t len = listxattr(path, NULL, 0, 0);
    
    // Ensure the size was determined.
    if (len <= 0)
        return NULL;
    
    // Create a new buffer.
    char *buf = calloc(len, sizeof(char));
    
    //
    ssize_t ret = listxattr(path, buf, len, 0);
    
    // Check if an error occurred.
    if (ret == -1)
        return NULL;
    
    // Create a new array to store the keys.
    NSMutableArray *keys = [NSMutableArray array];
    
    // Enumerate the names in the buffer.
    for (int i = 0; i < len; i += strlen(&buf[i]) + 1) {
        // Create an NSString from the C-String.
        const char *value = &buf[i];
        [keys addObject:[NSString stringWithUTF8String:value]];
    }
    
    // Release the buffer.
    free(buf);
    
    return keys;
}

- (NSString *)attributeForKey:(NSString *)key {
    // Define values to use with getxattr().
    const char *path = [_fileURL fileSystemRepresentation];
    const char *name = [key UTF8String];
    
    // Determine the length of the data.
    ssize_t len = getxattr(path, name, NULL, 0, 0, 0);
    
    // Return NULL if the length is not greater than zero.
    if (len <= 0)
        return NULL;
    
    // Create a chunk of memory for the value.
    NSString *attributeValue = NULL;
    char *value = calloc(len + 1, 1);
    
    if (value) {
        // Retrieve the attribute.
        getxattr(path, name, value, len, 0, 0);
        
        // Use the C-String to create the attribute value.
        value[len] = '\0';
        attributeValue = [NSString stringWithUTF8String:value];
        
        // Release the value.
        free(value);
    }
    
    return attributeValue;
}

- (void)setAttribute:(NSString *)aString forKey:(NSString *)key {
    // Prepare the values.
    const char *path = [_fileURL fileSystemRepresentation];
    const char *name = [key UTF8String];
    
    // Remove the string value if aString is nil.
    if (!aString) {
        removexattr(path, name, 0);
    } else {
        // Get the value as a C-String.
        const char *value = [aString UTF8String];
        
        // Set the attribute on the file.
        setxattr(path, name, value, strlen(value), 0, 0);
    }
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)other {
    if (self == other) {
        return YES;
    } else if (![other isKindOfClass:[RFAssetAttributes class]]) {
        return NO;
    } else {
        return [self isEqualToAttributes:(RFAssetAttributes *)other];
    }
}

- (BOOL)isEqualToAttributes:(RFAssetAttributes *)other {
    return [self.fileURL isEqual:other.fileURL];
}

- (NSUInteger)hash {
    return [self.fileURL hash];
}

@end
