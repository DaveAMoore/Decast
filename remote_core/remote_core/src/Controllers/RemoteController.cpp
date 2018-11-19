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
        
        // Filter out messages originating from this sender.
        if (message != nullptr && message->getSenderID() != Device::currentDevice().getSerialNumber()) {
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
            handleCommandMessage(std::move(message));
            break;
        case MessageType::Training:
            handleTrainingMessage(std::move(message));
            break;
        case MessageType::CommandResponse:
        case MessageType::TrainingResponse:
            handleResponseMessage(std::move(message));
            break;
        default:
            break;
    }
}

void RemoteController::handleCommandMessage(std::unique_ptr<Message> message) {
    if (message->remote == nullptr || message->command == nullptr) {
        // Send a response message indicating the issue.
        auto responseMessage = std::make_unique<Message>(MessageType::CommandResponse);
        responseMessage->error = Error::InvalidParameters;
        this->sendMessage(std::move(responseMessage));
        
        return;
    }
    
    // Create copies of the remote and command.
    Remote remote(*message->remote.get());
    Command command(*message->command.get());
    
    // Send the command.
    hardwareController->sendCommandForRemoteWithCompletionHandler(command, remote, [&, remote, command](Error error) {
        // Create a response message.
        auto responseMessage = std::make_unique<Message>(MessageType::CommandResponse);
        responseMessage->remote = std::make_unique<Remote>(remote);
        responseMessage->command = std::make_unique<Command>(command);
        responseMessage->error = error;
        
        // Send the response.
        this->sendMessage(std::move(responseMessage));
    });
}

void RemoteController::handleTrainingMessage(std::unique_ptr<Message> message) {
    // Create a response.
    auto responseMessage = std::make_unique<Message>(MessageType::TrainingResponse);
    responseMessage->directive = message->directive;
    
    // Handle the message and the directives.
    if (message->remote == nullptr) {
        responseMessage->error = Error::InvalidParameters;
    } else {
        responseMessage->remote = std::make_unique<Remote>(*message->remote.get());
        
        if (message->directive == START_TRAINING_SESSION_DIRECTIVE) {
            if (trainingSession == nullptr) {
                trainingSession = hardwareController->newTrainingSessionForRemote(Remote(*message->remote.get()));
                
                trainingSession->setDelegate(shared_from_this());
                hardwareController->startTrainingSession(trainingSession);
            } else {
                responseMessage->error = Error::TrainingAlreadyInSession;
            }
        } else if (message->directive == SUSPEND_TRAINING_SESSION_DIRECTIVE) {
            if (trainingSession != nullptr) {
                hardwareController->suspendTrainingSession(trainingSession);
                trainingSession = nullptr;
            }
        } else if (message->directive == CREATE_COMMAND_DIRECTIVE) {
            if (trainingSession != nullptr) {
                auto localizedTitle = message->command == nullptr ? "" : message->command->getLocalizedTitle();
                auto command = trainingSession->createCommandWithLocalizedTitle(localizedTitle);
                responseMessage->command = std::make_unique<Command>(command);
            } else {
                responseMessage->error = Error::NoTrainingSession;
            }
        } else if (message->directive == LEARN_COMMAND_DIRECTIVE) {
            if (trainingSession != nullptr) {
                if (message->command != nullptr) {
                    trainingSession->learnCommand(Command(*message->command.get()));
                } else {
                    responseMessage->error = Error::InvalidParameters;
                }
            } else {
                responseMessage->error = Error::NoTrainingSession;
            }
        } else {
            responseMessage->error = Error::InvalidDirective;
        }
    }
    
    // Send the response.
    sendMessage(std::move(responseMessage));
}

void RemoteController::handleResponseMessage(std::unique_ptr<Message> message) {
    
}

void RemoteController::sendMessage(std::unique_ptr<Message> message) {
    auto container = std::make_unique<JSONContainer>();
    auto aCoder = std::make_unique<Coder>(std::move(container));
    aCoder->encodeRootObject(message.get());
    
    auto codedContainer = aCoder->invalidateCoder();
    
    auto data = codedContainer->generateData();
    auto topic = topicForDeviceWithUserID(Device::currentDevice(), userID);
    connectionManager->publishMessageToTopic(data, topic, [](awsiotsdk::ResponseCode responseCode) {
        
    });
}

// MARK: - Training Session Delegate

void RemoteController::sendTrainingMessageForSession(TrainingSession *session, Command *command, std::string directive) {
    auto message = std::make_unique<Message>(MessageType::Training);
    auto remote = session->getAssociatedRemote();
    message->remote = std::make_unique<Remote>(remote);
    if (command != nullptr) {
        message->command = std::make_unique<Command>(*command);
    }
    message->directive = directive;
    
    sendMessage(std::move(message));
}

void RemoteController::trainingSessionDidBegin(TrainingSession *session) {
    sendTrainingMessageForSession(session, nullptr, TRAINING_SESSION_DID_BEGIN_DIRECTIVE);
}

void RemoteController::trainingSessionDidFailWithError(TrainingSession *session, Error error) {
    sendTrainingMessageForSession(session, nullptr, TRAINING_SESSION_DID_FAIL_WITH_ERROR_DIRECTIVE);
}

void RemoteController::trainingSessionWillLearnCommand(TrainingSession *session, Command command) {
    sendTrainingMessageForSession(session, &command, TRAINING_SESSION_WILL_LEARN_COMMAND_DIRECTIVE);
}

void RemoteController::trainingSessionDidLearnCommand(TrainingSession *session, Command command) {
    sendTrainingMessageForSession(session, &command, TRAINING_SESSION_DID_LEARN_COMMAND_DIRECTIVE);
}

void RemoteController::trainingSessionDidRequestInclusiveArbitraryInput(TrainingSession *session) {
    sendTrainingMessageForSession(session, nullptr, TRAINING_SESSION_DID_REQUEST_INCLUSIVE_ARBITRARY_INPUT_DIRECTIVE);
}

void RemoteController::trainingSessionDidRequestInputForCommand(TrainingSession *session, Command command) {
    sendTrainingMessageForSession(session, &command, TRAINING_SESSION_DID_REQUEST_INPUT_FOR_COMMAND_DIRECTIVE);
}

void RemoteController::trainingSessionDidRequestExclusiveArbitraryInput(TrainingSession *session) {
    sendTrainingMessageForSession(session, nullptr, TRAINING_SESSION_DID_REQUEST_EXCLUSIVE_ARBITRARY_INPUT_DIRECTIVE);
}

