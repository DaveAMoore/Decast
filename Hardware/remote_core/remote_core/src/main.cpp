//
//  main.cpp
//  remote_core
//
//  Created by David Moore on 10/21/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include <iostream>
#include <memory>
#include <thread>
#include <signal.h>
#include "RemoteController.hpp"

#define CONFIG_FILE_RELATIVE_PATH "config/remote_core_config.json"

// MARK: - Signal Interface

/// Last signal that was received.
static volatile std::atomic_int lastSignal(0);

/// Updates `lastSignal` with the received signal.
void handleSignal(int signum) {
    lastSignal = signum;
}

// MARK: - Lifecycle

int main(int argc, const char * argv[]) {
    // Provide a signal handler for termination and hangup.
    signal(SIGTERM, &handleSignal);
    signal(SIGHUP, &handleSignal);
    
    // Create a remote controller, then start it.
    auto remoteController = std::make_unique<RemoteCore::RemoteController>(CONFIG_FILE_RELATIVE_PATH);
    remoteController->startController();
    
    // Maintain a run-loop while the program is ongoing.
    while (true) {
        if (lastSignal == SIGHUP) {
            // Reload the configuration file by restarting the controller.
            remoteController->stopController();
            remoteController->startController();
        } else if (lastSignal == SIGTERM) {
            // Exit cleanly.
            break;
        }
        
        // Reset the signal.
        lastSignal = 0;
    }
    
    // Disconnect from the connection manager.
    remoteController->stopController();
    
    return 0;
}
