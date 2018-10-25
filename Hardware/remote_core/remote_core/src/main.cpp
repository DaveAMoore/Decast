//
//  main.cpp
//  remote_core
//
//  Created by David Moore on 10/21/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include <iostream>
#include "ConnectionManager.hpp"

#include <future>
#include <thread>
#include <unistd.h>
#include <CoreFoundation/CoreFoundation.h>

using namespace remote_core;

void loop(void) {
    while (true) {};
}

int main(int argc, const char * argv[]) {
    auto connectionManager = std::make_unique<ConnectionManager>("config/remote_core_config.json");
    awsiotsdk::ResponseCode responseCode = connectionManager->resumeConnection();
    
    std::cout << "Response code: " << responseCode << std::endl;
    
    connectionManager->subscribeToTopic("topic_1", [](std::string topicName, std::string payload) {
        return awsiotsdk::ResponseCode::SUCCESS;
    }, [](awsiotsdk::ResponseCode responseCode) {
        std::cout << responseCode << std::endl;
    });
    
    while (true) {
        std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    }
    
    /*auto future = std::async(&test);
    std::unique_ptr<ConnectionManager> f = future.get();
    
    //auto r = std::make_unique<std::thread>(test);
    //r->detach();
    
    auto t = std::make_unique<std::thread>(loop);
    t->join();*/
    
    //while (true) {
        // std::this_thread::sleep_for(std::chrono::milliseconds(1));
    //}
    
    return 0;
}
