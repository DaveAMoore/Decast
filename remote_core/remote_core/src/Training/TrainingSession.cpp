//
//  TrainingSession.cpp
//  remote_core
//
//  Created by David Moore on 11/5/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include "TrainingSession.hpp"
#include "UUID.hpp"
#include "Coder.hpp"
#include "JSONContainer.hpp"
#include <exception>

using namespace RemoteCore;

TrainingSession::TrainingSession(Remote associatedRemote) : associatedRemote(associatedRemote) {
    sessionID = UUID::GenerateUUIDString();
    
    // availableCommandIDs =
    
    // Sort a copied version of the available command IDs.
    auto sortedCommandIDs = availableCommandIDs;
    std::sort(sortedCommandIDs.begin(), sortedCommandIDs.end());
    
    auto sortedCommands = associatedRemote.commands;
    std::sort(sortedCommands.begin(), sortedCommands.end(), [](Command &lhs, Command &rhs) {
        return lhs.getCommandID() > rhs.getCommandID();
    });
}

Command TrainingSession::createCommandWithLocalizedTitle(std::string localizedTitle) {
    auto command = Command("[Command ID Here]", localizedTitle);
    associatedRemote.commands.push_back(command);
    
    return command;
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
