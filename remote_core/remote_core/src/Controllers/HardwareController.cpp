//
//  HardwareController.cpp
//  remote_core
//
//  Created by David Moore on 11/5/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include <algorithm>
#include <thread>
#include "HardwareController.hpp"
#include "lirc_client.h"

using namespace RemoteCore;

HardwareController::HardwareController() {
    
}

void HardwareController::sendCommandForRemoteWithCompletionHandler(Command command, Remote remote,
                                                                   CompletionHandler completionHandler) {
    /* ***************** Send the command. ***************** */
    
    // Create a lirc thread that handles the sending.
    auto lircThread = std::thread([completionHandler]() {
        // initialize lirc socket and store file descriptor
        int fd = lirc_init("remote_core", 0);
        if (fd == -1) {
            // Handle init fail
        }

        // Check for remote existence
        /*
         if (is_in_remotes() == -1) {
         // Handle remote not found
         }
         */

        // Send command
        if (lirc_send_one(lirc_get_local_socket(NULL, 1), remote.getRemoteID().c_str(), command.getCommandID().c_str()) == -1) {
            // Handle fail send
        }

        // Deinitialize lirc socket
        lirc_deinit();
        
        completionHandler(Error::None);
    });
    
    // Detach the thread.
    lircThread.detach();
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
    
    /* ***************** Start the training session. ***************** */
}

void HardwareController::suspendTrainingSession(std::shared_ptr<TrainingSession> trainingSession) {
    if (currentTrainingSession != trainingSession) {
        return;
    }
    
    /* ***************** Stop the training session. ***************** */
    
    // Nullify our reference to the training session.
    currentTrainingSession = nullptr;
}

void HardwareController::invalidateTrainingSession(std::shared_ptr<TrainingSession> trainingSession) {
    if (trainingSession == nullptr || trainingSession == currentTrainingSession) {
        return;
    }
    
    // Locate the session identifier, then delete it if found.
    auto position = std::find(sessionIDs.begin(), sessionIDs.end(), trainingSession->getSessionID());
    if (position != sessionIDs.end()) {
        sessionIDs.erase(position);
    }
}
