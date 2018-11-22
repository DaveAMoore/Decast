//
//  AWSCognitoIdentityProviderASF.h
//  AWSCognitoIdentityProviderASF
//
//  Created by David Moore on 6/5/18.
//  Copyright © 2018 Moore Development. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for AWSCognitoIdentityProviderASF.
FOUNDATION_EXPORT double AWSCognitoIdentityProviderASFVersionNumber;

//! Project version string for AWSCognitoIdentityProviderASF.
FOUNDATION_EXPORT const unsigned char AWSCognitoIdentityProviderASFVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <AWSCognitoIdentityProviderASF/PublicHeader.h>

@interface AWSCognitoIdentityProviderASF : NSObject

+ (NSString  * _Nullable) userContextData: (NSString* _Nonnull) userPoolId username: (NSString * _Nullable) username deviceId: (NSString * _Nullable ) deviceId userPoolClientId: (NSString * _Nonnull) userPoolClientId;

@end
