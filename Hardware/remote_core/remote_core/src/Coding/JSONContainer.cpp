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

// MARK: - Initialization

JSONContainer::JSONContainer() {
    internalContainer = json::object();
}

JSONContainer::JSONContainer(std::string payload) {
    internalContainer = json::parse(payload);
}

// MARK: - Encoding

void JSONContainer::setIntForKey(int value, std::string key) {
    internalContainer[key] = value;
}

void JSONContainer::setUnsignedIntForKey(unsigned int value, std::string key) {
    internalContainer[key] = value;
}

void JSONContainer::setFloatForKey(double value, std::string key) {
    internalContainer[key] = value;
}

void JSONContainer::setBoolForKey(bool value, std::string key) {
    internalContainer[key] = value;
}

void JSONContainer::setStringForKey(std::string value, std::string key) {
    internalContainer[key] = value;
}

std::unique_ptr<Container> JSONContainer::createNestedContainer() {
    return std::make_unique<JSONContainer>();
}

void JSONContainer::setNestedContainerForKey(std::unique_ptr<Container> nestedContainer, std::string key) {
    auto castNestedContainer = std::unique_ptr<JSONContainer>(static_cast<JSONContainer *>(nestedContainer.release()));
    internalContainer[key] = castNestedContainer->internalContainer;
}

// MARK: - Decoding

int JSONContainer::intForKey(std::string key) {
    auto value = internalContainer[key];
    if (value.is_number()) {
        return value.get<int>();
    } else {
        return 0;
    }
}

unsigned int JSONContainer::unsignedIntForKey(std::string key) {
    auto value = internalContainer[key];
    if (value.is_number()) {
        return value.get<unsigned int>();
    } else {
        return 0;
    }
}

double JSONContainer::floatForKey(std::string key) {
    auto value = internalContainer[key];
    if (value.is_number()) {
        return value.get<double>();
    } else {
        return 0.0;
    }
}

bool JSONContainer::boolForKey(std::string key) {
    auto value = internalContainer[key];
    if (value.is_boolean()) {
        return value.get<bool>();
    } else {
        return false;
    }
}

std::string JSONContainer::stringForKey(std::string key) {
    auto value = internalContainer[key];
    if (value.is_string()) {
        return value.get<std::string>();
    } else {
        return "";
    }
}

std::unique_ptr<Container> JSONContainer::containerForKey(std::string key) {
    auto value = internalContainer[key];
    if (value.is_object()) {
        auto container = std::make_unique<JSONContainer>(value.get<json>());
        return container;
    } else {
        return nullptr;
    }
}
