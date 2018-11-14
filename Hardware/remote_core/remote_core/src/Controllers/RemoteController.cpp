//
//  RemoteController.cpp
//  remote_core
//
//  Created by David Moore on 10/25/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include "RemoteController.hpp"
#include "ConfigCommon.hpp"

#define TOPIC_PREFIX "/remote_core/remotes/"

using namespace RemoteCore;
using namespace awsiotsdk;

RemoteController::RemoteController(const std::string &configFileRelativePath) {
    // Create a new connection manager.
    connectionManager = std::make_unique<ConnectionManager>(configFileRelativePath);
    
    // Retrieve the serial number.
    serialNumber = ConfigCommon::serial_number_;
}

void RemoteController::startController() {
    awsiotsdk::ResponseCode responseCode = connectionManager->resumeConnection();
    
    // TODO: Remove from debug build.
    std::cout << "Response code: " << responseCode << std::endl;
    
    connectionManager->subscribeToTopic(TOPIC_PREFIX + serialNumber, [&](std::string topicName, std::string payload) {
        return awsiotsdk::ResponseCode::SUCCESS;
    }, [](awsiotsdk::ResponseCode responseCode) {
        // FIXME: Handle errors.
    });
    
    /*connectionManager->subscribeToTopic("topic_1", [&](std::string topicName, std::string payload) {
        std::cout << payload << std::endl;
        
        std::string message = R"({"message": "Hello from Pi!"})";
        if (payload != message) {
            connectionManager->publishMessageToTopic(message, topicName, nullptr);
        }
        
        return awsiotsdk::ResponseCode::SUCCESS;
    }, [](awsiotsdk::ResponseCode responseCode) {
        std::cout << responseCode << std::endl;
    });*/
}

void RemoteController::stopController() {
    awsiotsdk::ResponseCode responseCode = connectionManager->suspendConnection();
    
    // TODO: Remove from debug build.
    std::cout << "Response code: " << responseCode << std::endl;
}
