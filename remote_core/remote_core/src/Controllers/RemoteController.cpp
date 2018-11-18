//
//  RemoteController.cpp
//  remote_core
//
//  Created by David Moore on 10/25/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include "RemoteController.hpp"
#include "Device.hpp"
#include "JSONContainer.hpp"
#include "Coder.hpp"
#include "ConfigCommon.hpp"

#define TOPIC_PREFIX "remote_core/account/"

using namespace RemoteCore;
using namespace awsiotsdk;

RemoteController::RemoteController(const std::string &configFileRelativePath) {
    // Create a new connection manager.
    connectionManager = std::make_unique<ConnectionManager>(configFileRelativePath);
    
    // Create a new hardware controller.
    hardwareController = std::make_unique<HardwareController>();
    
    userID = "us-east-1:b75c8125-eebe-4b20-8454-67a5edda2359";
}

std::string topicForDeviceWithUserID(Device device, std::string userID) {
    return "remote_core/account/" + userID + "/" + device.getSerialNumber();
}

void RemoteController::startController() {
    awsiotsdk::ResponseCode responseCode = connectionManager->resumeConnection();
    
    // TODO: Remove after debug build.
    std::cout << "Response code: " << responseCode << std::endl;
    
    subscribeToDefaultTopic();
}

void RemoteController::stopController() {
    awsiotsdk::ResponseCode responseCode = connectionManager->suspendConnection();
    
    // TODO: Remove from debug build.
    std::cout << "Response code: " << responseCode << std::endl;
}

void RemoteController::subscribeToDefaultTopic(void) {
    auto topic = topicForDeviceWithUserID(Device::currentDevice(), userID);
    connectionManager->subscribeToTopic(topic, [&](std::string topicName, std::string payload) {
        auto container = std::make_unique<JSONContainer>(payload);
        auto aCoder = std::make_unique<Coder>(std::move(container));
        auto message = aCoder->decodeRootObject<Message>();
        
        if (message != nullptr) {
            this->handleMessage(std::move(message));
            return awsiotsdk::ResponseCode::SUCCESS;
        } else {
            return awsiotsdk::ResponseCode::FAILURE;
        }
    }, [](awsiotsdk::ResponseCode responseCode) {
        // FIXME: Handle errors.
    });
}

void RemoteController::handleMessage(std::unique_ptr<Message> message) {
    switch (message->getMessageType()) {
        case MessageType::Default:
            break;
        case MessageType::Command:
            if (message->remote != nullptr && message->command != nullptr) {
                Remote remote(*message->remote.get());
                Command command(*message->command.get());
                
                hardwareController->sendCommandForRemoteWithCompletionHandler(command, remote, [&](Error error) {
                    auto message = std::make_unique<Message>(MessageType::Response);
                    message->error = error;
                    
                    this->sendMessage(std::move(message));
                });
            }
            break;
        case MessageType::Training:
            break;
        case MessageType::Response:
            break;
        default:
            break;
    }
}

void RemoteController::sendMessage(std::unique_ptr<Message> message) {
    auto container = std::make_unique<JSONContainer>();
    auto aCoder = std::make_unique<Coder>(std::move(container));
    aCoder->encodeRootObject(message.get());
    
    auto codedContainer = aCoder->invalidateCoder();
    
    size_t length = 0;
    auto data = codedContainer->generateData(&length);
    std::string jsonString((const char *)data.get(), length);
    
    auto topic = topicForDeviceWithUserID(Device::currentDevice(), userID);
    connectionManager->publishMessageToTopic(jsonString, topic, [](awsiotsdk::ResponseCode responseCode) {
        
    });
}
