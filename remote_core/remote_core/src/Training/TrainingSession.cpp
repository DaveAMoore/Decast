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
#include <iostream>

using namespace RemoteCore;

TrainingSession::TrainingSession(Remote associatedRemote) : associatedRemote(associatedRemote) {
    sessionID = UUID::GenerateUUIDString();
    
    // Read the command IDs in.
    auto container = std::make_unique<JSONContainer>(std::ifstream("config/remote_core_command_ids.json"));
    auto coder = std::make_unique<Coder>(std::move(container));
    
    // Sort a copied version of the available command IDs.
    auto sortedCommandIDs = coder->decodeRootArray<std::string>();
    std::sort(sortedCommandIDs.begin(), sortedCommandIDs.end());
    
    std::vector<std::string> sortedRemoteCommandIDs;
    for (auto &command : associatedRemote.commands) {
        sortedRemoteCommandIDs.push_back(command.getCommandID());
    }
    std::sort(sortedRemoteCommandIDs.begin(), sortedRemoteCommandIDs.end());
    
    availableCommandIDs = std::vector<std::string>();
    std::set_difference(sortedCommandIDs.begin(), sortedCommandIDs.end(),
                        sortedRemoteCommandIDs.begin(), sortedRemoteCommandIDs.end(),
                        std::inserter(availableCommandIDs, availableCommandIDs.end()));
}

void TrainingSession::start(void) {
    /* ***************** Start the training session. ***************** */
    
    // Call the appropriate delegate method.
    if (auto delegate = this->delegate.lock()) {
        delegate->trainingSessionDidBegin(this);
    }
}

void TrainingSession::suspend(void) {
    /* ***************** Stop the training session. ***************** */
}

Command TrainingSession::createCommandWithLocalizedTitle(std::string localizedTitle) {
    if (availableCommandIDs.empty()) {
        throw std::logic_error("Expected 'availableCommandIDs' to be non-empty.");
    }
    
    auto command = Command(localizedTitle, availableCommandIDs.back());
    associatedRemote.commands.push_back(command);
    availableCommandIDs.pop_back();
    
    // TODO: Handle the case when all of the available command IDs are gone.
    
    return command;
}

void TrainingSession::learnCommand(Command command) {
    if (currentCommand != Command()) {
        throw std::logic_error("Expected 'currentCommand' to be empty.");
    }
    
    // Call the delegate.
    if (auto delegate = this->delegate.lock()) {
        delegate->trainingSessionWillLearnCommand(this, command);
    }
    
    /* ***************** Learn the command. ***************** */

    // Call the delegate.
    if (auto delegate = this->delegate.lock()) {
        delegate->trainingSessionDidLearnCommand(this, command);
    }
}
