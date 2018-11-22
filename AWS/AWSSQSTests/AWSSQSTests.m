//
//  AWSSQSTests.m
//  AWSSQSTests
//
//  Created by David Moore on 6/5/18.
//  Copyright © 2018 Moore Development. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AWSSQS.h"
#import "AWSTestUtility.h"

@interface AWSSQSTests : XCTestCase

@end

@implementation AWSSQSTests

+ (void)setUp {
    [super setUp];
    [AWSTestUtility setupCognitoCredentialsProvider];
}

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

-(void)testClockSkewSQS {
    [AWSTestUtility setupSwizzling];
    
    XCTAssertFalse([NSDate aws_getRuntimeClockSkew], @"current RunTimeClockSkew is not zero!");
    [AWSTestUtility setMockDate:[NSDate dateWithTimeIntervalSince1970:3600]];
    
    AWSSQS *sqs = [AWSSQS defaultSQS];
    XCTAssertNotNil(sqs);
    
    AWSSQSListQueuesRequest *listQueuesRequest = [AWSSQSListQueuesRequest new];
    [[[sqs listQueues:listQueuesRequest] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            XCTFail(@"Error: [%@]", task.error);
        }
        
        if (task.result) {
            AWSSQSListQueuesResult *listQueuesResult = task.result;
            AWSDDLogDebug(@"[%@]", listQueuesResult);
            XCTAssertNotNil(listQueuesResult.queueUrls);
        }
        
        return nil;
    }] waitUntilFinished];
    
    [AWSTestUtility revertSwizzling];
}

- (void)testListQueuesRequest {
    AWSSQS *sqs = [AWSSQS defaultSQS];
    
    AWSSQSListQueuesRequest *listQueuesRequest = [AWSSQSListQueuesRequest new];
    [[[sqs listQueues:listQueuesRequest] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            XCTFail(@"Error: [%@]", task.error);
        }
        
        if (task.result) {
            AWSSQSListQueuesResult *listQueuesResult = task.result;
            AWSDDLogDebug(@"[%@]", listQueuesResult);
            XCTAssertNotNil(listQueuesResult.queueUrls);
        }
        
        return nil;
    }] waitUntilFinished];
}

- (void)testGetQueueAttributesRequestFailure {
    AWSSQS *sqs = [AWSSQS defaultSQS];
    
    AWSSQSGetQueueAttributesRequest *attributesRequest = [AWSSQSGetQueueAttributesRequest new];
    attributesRequest.queueUrl = @""; //queueURL is empty
    
    [[[sqs getQueueAttributes:attributesRequest] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error, @"expected InvalidAddress Error but got nil");
        XCTAssertEqual(task.error.code, 0);
        XCTAssertTrue([@"InvalidAddress" isEqualToString:task.error.userInfo[@"Code"]]);
        XCTAssertTrue([@"The address  is not valid for this endpoint." isEqualToString:task.error.userInfo[@"Message"]]);
        return nil;
    }] waitUntilFinished];
}

@end
