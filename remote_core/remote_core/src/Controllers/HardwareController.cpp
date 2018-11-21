//
//  HardwareController.cpp
//  remote_core
//
//  Created by David Moore on 11/5/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include <algorithm>
#include <thread>
#include <sys/stat.h>
#include "HardwareController.hpp"
#include "CommandLine.hpp"

#define REMOTE_CONFIGURATION_FILE_DIRECTORY "."

using namespace RemoteCore;

HardwareController::HardwareController() {
    
}

bool HardwareController::doesRemoteExist(Remote &remote) {
    auto relativePath = (REMOTE_CONFIGURATION_FILE_DIRECTORY + remote.getRemoteID() + ".lircd.conf").c_str();
    struct stat buffer;
    
    return (stat (relativePath, &buffer) == 0);
}

void HardwareController::sendCommandForRemoteWithCompletionHandler(Command command, Remote remote,
                                                                   CompletionHandler completionHandler) {
    /* ***************** Send the command. ***************** */
    
    auto commandString = "irsend SEND_ONCE " + remote.getRemoteID() + " " + command.getCommandID();
    CommandLine::sharedCommandLine()->executeCommandWithResultHandler(commandString.c_str(), [=](std::string result, bool isComplete) {
        if (isComplete) {
            completionHandler(Error::None);
        }
    });
    
//    // Create a lirc thread that handles the sending.
//    auto lircThread = std::thread([completionHandler]() {
//        // initialize lirc socket and store file descriptor
//        int fd = lirc_init("remote_core", 0);
//        if (fd == -1) {
//            // Handle init fail
//        }
//
//        // Check for remote existence
//        /*
//         if (!checkRemoteConfig(remote.getRemoteID)) {
//         // Handle remote not found
//         }
//         */
//
//        // Send command
//        if (lirc_send_one(lirc_get_local_socket(NULL, 1), remote.getRemoteID().c_str(), command.getCommandID().c_str()) == -1) {
//            // Handle fail send
//        }
//
//        // Deinitialize lirc socket
//        lirc_deinit();
//
//        completionHandler(Error::None);
 //   });
    
    // Detach the thread.
    // lircThread.detach();
}

std::shared_ptr<TrainingSession> HardwareController::newTrainingSessionForRemote(Remote remote) {
    // Create a new training session.
    auto trainingSession = std::make_shared<TrainingSession>(remote);
    
    // Keep the session identifier stored.
    sessionIDs.push_back(trainingSession->getSessionID());
    
    return trainingSession;
}

void HardwareController::startTrainingSession(std::shared_ptr<TrainingSession> trainingSession) {
    // It is an error to start a new training session when there is currently an active session.
    if (currentTrainingSession != nullptr) {
        throw std::logic_error("Expected 'currentTrainingSession' to be nullptr.");
    }
    
    // Retain the training session.
    currentTrainingSession = trainingSession;
    
    // Start the training session.
    currentTrainingSession->start();
}

void HardwareController::suspendTrainingSession(std::shared_ptr<TrainingSession> trainingSession) {
    if (currentTrainingSession != trainingSession) {
        return;
    }
    
    // Suspend the training session.
    currentTrainingSession->suspend();
    
    // Nullify our reference to the training session.
    currentTrainingSession = nullptr;
}
