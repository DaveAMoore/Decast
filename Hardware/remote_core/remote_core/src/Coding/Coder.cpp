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
    codingContainer->setIntForKey(value, key);
}

void Coder::encodeUnsignedIntForKey(unsigned int value, std::string key) {
    codingContainer->setUnsignedIntForKey(value, key);
}

void Coder::encodeFloatForKey(double value, std::string key) {
    codingContainer->setFloatForKey(value, key);
}

void Coder::encodeBoolForKey(bool value, std::string key) {
    codingContainer->setBoolForKey(value, key);
}

void Coder::encodeStringForKey(std::string value, std::string key) {
    codingContainer->setStringForKey(value, key);
}

void Coder::encodeObjectForKey(const Coding &object, std::string key) {
    auto embeddedContainer = codingContainer->requestNestedContainer();
    auto aCoder = std::make_unique<Coder>(std::move(embeddedContainer));
}

int Coder::decodeIntForKey(std::string key) {
    return codingContainer->intForKey(key);
}

unsigned int Coder::decodeUnsignedIntForKey(std::string key) {
    return codingContainer->unsignedIntForKey(key);
}

double Coder::decodeFloatForKey(std::string key) {
    return codingContainer->floatForKey(key);
}

bool Coder::decodeBoolForKey(std::string key) {
    return codingContainer->boolForKey(key);
}

std::string Coder::decodeStringForKey(std::string key) {
    return codingContainer->stringForKey(key);
}
