//
//  Coder.cpp
//  remote_core
//
//  Created by David Moore on 10/31/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include "Coder.hpp"

using namespace RemoteCore;

void Coder::encodeIntForKey(int value, std::string key) {
    codingContainer->encodeIntForKey(value, key);
}

void Coder::encodeBoolForKey(bool value, std::string key) {
    codingContainer->encodeBoolForKey(value, key);
}

void Coder::encodeStringForKey(std::string value, std::string key) {
    codingContainer->encodeStringForKey(value, key);
}

void Coder::encodeObjectForKey(const Coding &object, std::string key) {
    // TODO: Implement object encoding.
    static_assert(true, "Not implemented yet");
}

int Coder::decodeIntForKey(std::string key) {
    return codingContainer->decodeIntForKey(key);
}

bool Coder::decodeBoolForKey(std::string key) {
    return codingContainer->decodeBoolForKey(key);
}

std::string Coder::decodeStringForKey(std::string key) {
    return codingContainer->decodeStringForKey(key);
}
