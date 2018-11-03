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

void JSONContainer::encodeIntForKey(int value, std::string key) {
    internalContainer[key] = value;
}

void JSONContainer::encodeBoolForKey(bool value, std::string key) {
    internalContainer[key] = value;
}

void JSONContainer::encodeStringForKey(std::string value, std::string key) {
    internalContainer[key] = value;
}

std::unique_ptr<Container> JSONContainer::requestEncodableContainer() {
    return std::make_unique<JSONContainer>();
}

void JSONContainer::submitEncodableContainerForKey(std::unique_ptr<Container> encodableContainer, std::string key) {
    auto castEncodableContainer = std::unique_ptr<JSONContainer>(static_cast<JSONContainer *>(encodableContainer.release()));
    internalContainer[key] = castEncodableContainer->internalContainer;
}

// MARK: - Decoding

int JSONContainer::intForKey(std::string key) {
    return internalContainer[key].get<int>();
}

bool JSONContainer::boolForKey(std::string key) {
    return internalContainer[key].get<bool>();
}

std::string JSONContainer::stringForKey(std::string key) {
    return internalContainer[key].get<std::string>();
}

std::unique_ptr<Container> JSONContainer::containerForKey(std::string key) {
    auto value = internalContainer[key].get<json>();
    auto container = std::make_unique<JSONContainer>(value);
    
    return container;
}
