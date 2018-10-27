//
//  RemoteController.cpp
//  remote_core
//
//  Created by David Moore on 10/25/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include "RemoteController.hpp"

using namespace RemoteCore;
using namespace awsiotsdk;

RemoteController::RemoteController(const std::string &configFileRelativePath) {
    // Create a new 
    connectionManager = std::make_unique<ConnectionManager>(configFileRelativePath);
}

void RemoteController::startController() {
    awsiotsdk::ResponseCode responseCode = connectionManager->resumeConnection();
    
    // TODO: Remove from debug build.
    std::cout << "Response code: " << responseCode << std::endl;
    
    connectionManager->subscribeToTopic("topic_1", [](std::string topicName, std::string payload) {
        std::cout << payload << std::endl;
        return awsiotsdk::ResponseCode::SUCCESS;
    }, [](awsiotsdk::ResponseCode responseCode) {
        std::cout << responseCode << std::endl;
    });
}

void RemoteController::stopController() {
    awsiotsdk::ResponseCode responseCode = connectionManager->suspendConnection();
    
    // TODO: Remove from debug build.
    std::cout << "Response code: " << responseCode << std::endl;
}
