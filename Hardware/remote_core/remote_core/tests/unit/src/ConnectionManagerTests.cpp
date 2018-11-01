//
//  ConnectionManagerTests.cpp
//  remote_core
//
//  Created by David Moore on 10/27/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include <memory>
#include <future>
#include <gtest/gtest.h>
#include "ConnectionManager.hpp"

using namespace awsiotsdk;
using namespace RemoteCore;
using namespace testing;

#define DEFAULT_TIMEOUT std::chrono::seconds(15)
#define DEFAULT_TOPIC_NAME "topic_1"
#define ALTERNATE_TOPIC_NAME "topic_2"

// MARK: - Test Fixture

class ConnectionManagerTests : public testing::Test {
protected:
    /// Connection manager object that will be setup with the configuration file.
    std::shared_ptr<ConnectionManager> connectionManager;
    
    void SetUp() override {
        connectionManager = std::make_shared<ConnectionManager>("config/remote_core_config.json");
    }
};

// MARK: - Tests

TEST_F(ConnectionManagerTests, ResumeAndSuspendConnection) {
    // Establish the connection.
    ResponseCode responseCode = connectionManager->resumeConnection();
    ASSERT_EQ(responseCode, ResponseCode::MQTT_CONNACK_CONNECTION_ACCEPTED);
    
    // Suspend the connection.
    responseCode = connectionManager->suspendConnection();
    EXPECT_EQ(responseCode, ResponseCode::SUCCESS);
}

TEST_F(ConnectionManagerTests, SubscribeToTopic) {
    // Establish the connection.
    ResponseCode responseCode = connectionManager->resumeConnection();
    ASSERT_EQ(responseCode, ResponseCode::MQTT_CONNACK_CONNECTION_ACCEPTED);
    
    std::promise<void> completionHandlerPromise;
    std::promise<void> alternateCompletionHandlerPromise;
    
    // Subscribe to the default topic.
    connectionManager->subscribeToTopic(DEFAULT_TOPIC_NAME, [](std::string topicName, std::string payload) {
        return ResponseCode::SUCCESS;
    }, [&](ResponseCode responseCode) {
        EXPECT_EQ(responseCode, ResponseCode::SUCCESS);
        completionHandlerPromise.set_value();
    });
    
    // Subscribe to the alternate topic.
    connectionManager->subscribeToTopic(ALTERNATE_TOPIC_NAME, [](std::string topicName, std::string payload) {
        return ResponseCode::SUCCESS;
    }, [&](ResponseCode responseCode) {
        EXPECT_EQ(responseCode, ResponseCode::SUCCESS);
        alternateCompletionHandlerPromise.set_value();
    });
    
    // Wait for the futures.
    ASSERT_EQ(completionHandlerPromise.get_future().wait_for(DEFAULT_TIMEOUT), std::future_status::ready);
    ASSERT_EQ(alternateCompletionHandlerPromise.get_future().wait_for(DEFAULT_TIMEOUT), std::future_status::ready);
    
    // Check the subscribed topic names.
    auto subscribedTopicNames = connectionManager->getSubscribedTopicNames();
    EXPECT_EQ(subscribedTopicNames.size(), 2);
    EXPECT_EQ(subscribedTopicNames.at(0), DEFAULT_TOPIC_NAME);
    EXPECT_EQ(subscribedTopicNames.at(1), ALTERNATE_TOPIC_NAME);
    
    // Suspend the connection.
    responseCode = connectionManager->suspendConnection();
    EXPECT_EQ(responseCode, ResponseCode::SUCCESS);
}

TEST_F(ConnectionManagerTests, UnsubscribeFromTopic) {
    // Establish the connection.
    ResponseCode responseCode = connectionManager->resumeConnection();
    ASSERT_EQ(responseCode, ResponseCode::MQTT_CONNACK_CONNECTION_ACCEPTED);
    
    std::promise<void> subscribePromise;
    std::promise<void> unsubscribePromise;
    
    // Subscribe to the default topic.
    connectionManager->subscribeToTopic(DEFAULT_TOPIC_NAME, [](std::string topicName, std::string payload) {
        return ResponseCode::SUCCESS;
    }, [&](ResponseCode responseCode) {
        EXPECT_EQ(responseCode, ResponseCode::SUCCESS);
        subscribePromise.set_value();
    });
    
    // Wait for the future.
    ASSERT_EQ(subscribePromise.get_future().wait_for(DEFAULT_TIMEOUT), std::future_status::ready);
    
    // Unsubscribe from the default topic.
    connectionManager->unsubscribeFromTopic(DEFAULT_TOPIC_NAME, [&](ResponseCode responseCode) {
        EXPECT_EQ(responseCode, ResponseCode::SUCCESS);
        unsubscribePromise.set_value();
    });
    
    // Wait for the future.
    ASSERT_EQ(unsubscribePromise.get_future().wait_for(DEFAULT_TIMEOUT), std::future_status::ready);
    
    // Check to make sure there are no more subscribed topic names.
    auto subscribedTopicNames = connectionManager->getSubscribedTopicNames();
    EXPECT_TRUE(subscribedTopicNames.empty());
    
    // Suspend the connection.
    responseCode = connectionManager->suspendConnection();
    EXPECT_EQ(responseCode, ResponseCode::SUCCESS);
}

TEST_F(ConnectionManagerTests, PublishMessageToTopic) {
    // Establish the connection.
    ResponseCode responseCode = connectionManager->resumeConnection();
    ASSERT_EQ(responseCode, ResponseCode::MQTT_CONNACK_CONNECTION_ACCEPTED);
    
    // Declare the payload that will be sent.
    const std::string baselinePayload = R"({"message":"ConnectionManagerTests -> SubscribeToTopic"})";
    
    std::promise<void> subscribePromise;
    std::promise<void> messageHandlerPromise;
    std::promise<void> completionHandlerPromise;
    std::promise<void> unsubscribePromise;
    
    // Subscribe to the default topic.
    connectionManager->subscribeToTopic(DEFAULT_TOPIC_NAME, [&](std::string topicName, std::string payload) {
        EXPECT_EQ(baselinePayload, payload);
        messageHandlerPromise.set_value();
        
        return ResponseCode::SUCCESS;
    }, [&](ResponseCode responseCode) {
        EXPECT_EQ(responseCode, ResponseCode::SUCCESS);
        subscribePromise.set_value();
    });
    
    // Wait for the future.
    ASSERT_EQ(subscribePromise.get_future().wait_for(DEFAULT_TIMEOUT), std::future_status::ready);
    
    // Publish the message.
    connectionManager->publishMessageToTopic(baselinePayload, DEFAULT_TOPIC_NAME, [&](ResponseCode responseCode) {
        EXPECT_EQ(responseCode, ResponseCode::SUCCESS);
        completionHandlerPromise.set_value();
    });
    
    // Wait for the future.
    ASSERT_EQ(completionHandlerPromise.get_future().wait_for(DEFAULT_TIMEOUT), std::future_status::ready);
    ASSERT_EQ(messageHandlerPromise.get_future().wait_for(DEFAULT_TIMEOUT), std::future_status::ready);
    
    // Unsubscribe from the default topic.
    connectionManager->unsubscribeFromTopic(DEFAULT_TOPIC_NAME, [&](ResponseCode responseCode) {
        EXPECT_EQ(responseCode, ResponseCode::SUCCESS);
        unsubscribePromise.set_value();
    });
    
    // Wait for the future.
    ASSERT_EQ(unsubscribePromise.get_future().wait_for(DEFAULT_TIMEOUT), std::future_status::ready);
    
    // Suspend the connection.
    responseCode = connectionManager->suspendConnection();
    EXPECT_EQ(responseCode, ResponseCode::SUCCESS);
}
