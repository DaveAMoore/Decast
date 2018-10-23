//
//  main.cpp
//  remote_core
//
//  Created by David Moore on 10/21/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include <iostream>
#include "ConnectionManager.hpp"

using namespace remote_core;

int main(int argc, const char * argv[]) {
    auto connectionManager = std::make_unique<ConnectionManager>("config/remote_core_config.json");
    awsiotsdk::ResponseCode responseCode = connectionManager->resumeConnection();
    
    std::cout << "Response code: " << responseCode << std::endl;
    
    return 0;
}
