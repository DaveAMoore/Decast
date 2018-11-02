//
//  JSONContainer.cpp
//  remote_core
//
//  Created by David Moore on 11/1/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include "JSONContainer.hpp"

using json = nlohmann::json;
using namespace RemoteCore;

void Container::encodeIntForKey(int value, std::string key) {
    
}

void Container::encodeBoolForKey(bool value, std::string key) {
    
}

void Container::encodeStringForKey(std::string value, std::string key) {
    
}

int Container::decodeIntForKey(std::string key) {
    return 0;
}

bool Container::decodeBoolForKey(std::string key) {
    return false;
}

std::string Container::decodeStringForKey(std::string key) {
    return "";
}
