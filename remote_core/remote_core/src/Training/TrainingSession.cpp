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
#include "CommandLine.hpp"
#include <exception>
#include <iostream>
#include <fstream>
#include <thread>

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

void TrainingSession::addNewRemoteConfigToDefaultConfig(Remote remote) {
    // Initialize and set reader to new remote config / writer to default config appending to end of file
    std::ofstream fileWriter;
    std::ifstream fileReader;
    fileWriter.open("/etc/lirc/lircd.conf", std::ios::app);
    fileReader.open("remotes/" + remote.getRemoteID() + ".lircd.conf");

    // Set up for finding remote declaration in new config file
    bool isRemoteNotDeclared = true;
    std::string line;

    if (fileReader.is_open() && fileWriter.is_open()) {
        // Set reader to begin of remote declaration
        while (isRemoteNotDeclared) {
            std::getline(fileReader, line);
            if (line.find("begin remote") != std::string::npos) {
                isRemoteNotDeclared = false;
                fileWriter << "\n" << line << "\n";
            }
        }

        // Write/Read parallel to config files
        while (std::getline(fileReader, line)) {
            if (line.find("end remote") != std::string::npos) {
                fileWriter << line << "\n";
                break;
            }
            fileWriter << line << "\n";
        }

        fileWriter.close();
        fileReader.close();
    } else {
        // Handle fileReader / fileWriter not open
    }
}

void TrainingSession::start(void) {
    /* ***************** Start the training session. ***************** */

//    std::string initiateRecord = "sudo /etc/init.d/lircd stop; irrecord";
//
//    // Call the delegate.
//    if (auto delegate = this->delegate.lock()) {
//        delegate->trainingSessionDidLearnCommand(this, command);
//    }
//
//    CommandLine::sharedCommandLine()->executeCommandWithResultHandler(initiateRecord.c_str(), [=](std::string result, bool isComplete) {
//        if (isComplete) {
//
//        }
//    });

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
        delegate->trainingSessionDidRequestInputForCommand(this, command);
    }
    
    /* ***************** Learn the command. ***************** */

    DispatchQueue queue("ca.mooredev.remote_core.TrainingSession.serial_dispatch_queue");
    queue.execute([this, command]() {
        std::this_thread::sleep_for(std::chrono::seconds(5));
        
        // Call the delegate.
        if (auto delegate = this->delegate.lock()) {
            delegate->trainingSessionDidLearnCommand(this, command);
        }
    });
}
