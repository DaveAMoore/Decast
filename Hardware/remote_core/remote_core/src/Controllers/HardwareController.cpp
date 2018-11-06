//
//  HardwareController.cpp
//  remote_core
//
//  Created by David Moore on 11/5/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include "HardwareController.hpp"

using namespace RemoteCore;

HardwareController::HardwareController() {
    
}

std::shared_ptr<TrainingSession> HardwareController::newTrainingSession() {
    // Create a new training session.
    auto trainingSession = std::make_shared<TrainingSession>();
    return trainingSession;
}

void HardwareController::startTrainingSession(std::shared_ptr<TrainingSession> trainingSession) {
    // It is an error to start a new training session when there is currently an active session.
    if (currentTrainingSession != nullptr) {
        throw std::logic_error("Expected 'currentTrainingSession' to be nullptr.");
    }
}

void HardwareController::suspendTrainingSession(std::shared_ptr<TrainingSession> trainingSession) {
    if (currentTrainingSession == trainingSession) {
        // Stop the current training session.
        // TODO: Stop the current training session.
        
        // Nullify our reference to the training session.
        currentTrainingSession = nullptr;
    }
}
