//
//  TrainingSession.cpp
//  remote_core
//
//  Created by David Moore on 11/5/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include "TrainingSession.hpp"
#include "UUID.hpp"
#include <exception>

using namespace RemoteCore;

TrainingSession::TrainingSession(Remote associatedRemote) : associatedRemote(associatedRemote) {
    sessionID = UUID::GenerateUUIDString();
}

Command TrainingSession::createCommandWithLocalizedTitle(std::string localizedTitle) {
    return Command("[Command ID Here]", localizedTitle);
}

void TrainingSession::learnCommand(Command command) {
    if (currentCommand != Command()) {
        throw std::logic_error("Expected 'currentCommand' to be empty.");
    }
    
    /* if (command.getAssociatedRemote() != associatedRemote) {
        throw std::logic_error("Expected 'command.associatedRemote' to be equal to 'associatedRemote'.");
    } */
    
    // Call the delegate.
    if (auto delegate = this->delegate.lock()) {
        delegate->trainingSessionWillLearnCommand(this, command);
    }
}
