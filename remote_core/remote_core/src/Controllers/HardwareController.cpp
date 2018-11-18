//
//  HardwareController.cpp
//  remote_core
//
//  Created by David Moore on 11/5/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include <algorithm>
#include "HardwareController.hpp"

using namespace RemoteCore;

HardwareController::HardwareController() {
    
}

void HardwareController::sendCommandForRemoteWithCompletionHandler(Command command, Remote remote,
                                                                   CompletionHandler completionHandler) {
    completionHandler(Error::None);
    /* ***************** Send the command .***************** */
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
