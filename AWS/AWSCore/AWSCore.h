//
//  AWSCore.h
//  AWSCore
//
//  Created by David Moore on 6/5/18.
//  Copyright © 2018 Moore Development. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for AWSCore.
FOUNDATION_EXPORT double AWSCoreVersionNumber;

//! Project version string for AWSCore.
FOUNDATION_EXPORT const unsigned char AWSCoreVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <AWSCore/PublicHeader.h>

#import <AWSCore/AWSCocoaLumberjack.h>

#import <AWSCore/AWSServiceEnum.h>
#import <AWSCore/AWSService.h>
#import <AWSCore/AWSCredentialsProvider.h>
#import <AWSCore/AWSIdentityProvider.h>
#import <AWSCore/AWSModel.h>
#import <AWSCore/AWSNetworking.h>
#import <AWSCore/AWSCategory.h>
#import <AWSCore/AWSLogging.h>
#import <AWSCore/AWSClientContext.h>
#import <AWSCore/AWSSynchronizedMutableDictionary.h>
#import <AWSCore/AWSSerialization.h>
#import <AWSCore/AWSURLRequestSerialization.h>
#import <AWSCore/AWSURLResponseSerialization.h>
#import <AWSCore/AWSURLSessionManager.h>
#import <AWSCore/AWSSignature.h>
#import <AWSCore/AWSURLRequestRetryHandler.h>
#import <AWSCore/AWSValidation.h>
#import <AWSCore/AWSInfo.h>
#import <AWSCore/AWSDevice.h>

#import <AWSCore/AWSBolts.h>
#import <AWSCore/AWSGZIP.h>
#import <AWSCore/AWSFMDB.h>
#import <AWSCore/AWSKSReachability.h>
#import <AWSCore/AWSTMCache.h>
#import <AWSCore/AWSKeyChainStore.h>

#import <AWSCore/AWSSTS.h>
#import <AWSCore/AWSCognitoIdentity.h>
