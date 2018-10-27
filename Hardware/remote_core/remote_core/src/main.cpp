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

static volatile sig_atomic_t shouldTerminate = 0;

void handleSignal(int signum) {
    switch (signum) {
    case SIGTERM:
        shouldTerminate = 1;
        break;
    default:
        break;
    }
}

int main(int argc, const char * argv[]) {
    // Create a remote controller, then start it.
    auto remoteController = std::make_unique<RemoteCore::RemoteController>(CONFIG_FILE_RELATIVE_PATH);
    remoteController->startController();
    
    // Maintain a run-loop while the program is ongoing.
    while (true) {
        if (shouldTerminate) {
            break;
        }
        
        //std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    }
    
    return 0;
}
