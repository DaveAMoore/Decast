//
//  ConnectionManagerTests.cpp
//  remote_core
//
//  Created by David Moore on 10/27/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include <memory>
#include <gtest/gtest.h>
#include "ConnectionManager.hpp"

using namespace awsiotsdk;
using namespace RemoteCore;

#define DEFAULT_TOPIC_NAME "topic_1"

// MARK: - Test Fixture

class ConnectionManagerTests : public testing::Test {
protected:
    std::shared_ptr<ConnectionManager> connectionManager;
    
    void SetUp() override {
        connectionManager = std::make_shared<ConnectionManager>("config/remote_core_config.json");
    }
};

// MARK: - Tests

TEST_F(ConnectionManagerTests, ResumeAndSuspendConnection) {
    ResponseCode responseCode = connectionManager->resumeConnection();
    ASSERT_EQ(responseCode, ResponseCode::MQTT_CONNACK_CONNECTION_ACCEPTED);
    
    responseCode = connectionManager->suspendConnection();
    ASSERT_EQ(responseCode, ResponseCode::SUCCESS);
}

TEST_F(ConnectionManagerTests, SubscribeToTopic) {
    /*connectionManager->subscribeToTopic(DEFAULT_TOPIC_NAME, <#MessageHandler messageHandler#>, <#CompletionHandler completionHandler#>);*/
}
