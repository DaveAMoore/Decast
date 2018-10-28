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

TEST(ConnectionManagerTests, ResumeAndSuspendConnection) {
    auto connectionManager = std::make_unique<ConnectionManager>("config/remote_core_config.json");
    
    ResponseCode responseCode = connectionManager->resumeConnection();
    ASSERT_EQ(responseCode, ResponseCode::MQTT_CONNACK_CONNECTION_ACCEPTED);
    
    responseCode = connectionManager->suspendConnection();
    ASSERT_EQ(responseCode, ResponseCode::SUCCESS);
}
