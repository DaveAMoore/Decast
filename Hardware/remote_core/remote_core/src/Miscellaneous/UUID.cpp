//
//  UUID.cpp
//  remote_core
//
//  Created by David Moore on 11/6/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include "UUID.hpp"

using namespace RemoteCore;

UUID::UUID() {
    uuid_generate(uuid);
}

std::string UUID::uuidString() {
    char uuidStr[64];
    uuid_unparse(uuid, uuidStr);
    
    return std::string(uuidStr);
}

