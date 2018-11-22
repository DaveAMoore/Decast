//
//  AWSDevice.m
//  AWSCore
//
//  Created by David Moore on 5/9/18.
//  Copyright © 2018 Amazon Web Services. All rights reserved.
//

#import "AWSDevice.h"
#include <sys/sysctl.h>
#import <AWSKeyChainStore.h>

#if TARGET_OS_IPHONE
#else

@implementation AWSDevice

+ (instancetype)currentDevice {
    static dispatch_once_t once;
    __strong static id _sharedObject = nil;
    
    dispatch_once(&once, ^{
        _sharedObject = [[self alloc] init];
    });
    
    return _sharedObject;
}

- (NSString *)name {
    return [[NSHost currentHost] localizedName];
}

- (NSString *)systemName {
#if TARGET_OS_OSX
    return @"OS X";
#else
    return @"iOS";
#endif
}

- (NSString *)systemVersion {
    return [[NSProcessInfo processInfo] operatingSystemVersionString];
}

- (NSString *)getSystemInformation:(char *)typeSpecifier {
    size_t infoSize;
    sysctlbyname(typeSpecifier, NULL, &infoSize, NULL, 0);
    
    char *systemInformation = malloc(infoSize);
    sysctlbyname(typeSpecifier, systemInformation, &infoSize, NULL, 0);
    
    NSString *informationString = [NSString stringWithCString:systemInformation
                                                     encoding:NSUTF8StringEncoding];
    free(systemInformation);
    
    return informationString;
}

- (NSString *)model {
    return [self getSystemInformation:"hw.model"];
}

- (NSUUID *)identifierForVendor {
    NSString *service = [NSString stringWithFormat:@"%@.%@", [[NSBundle mainBundle] bundleIdentifier], @"AWSCognito.UDID"];
    NSString *key = @"aws_udid_key";
    NSString *uuidString = [AWSKeyChainStore stringForKey:key service:service accessGroup:nil];
    
    if (uuidString) {
        return [[NSUUID alloc] initWithUUIDString:uuidString];
    }
    
    NSUUID *uuid = [[NSUUID alloc] init];
    [AWSKeyChainStore setString:[uuid UUIDString] forKey:key service:service accessGroup:nil];
    
    return uuid;
}

@end

#endif
