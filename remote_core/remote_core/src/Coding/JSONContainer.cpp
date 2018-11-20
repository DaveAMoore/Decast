//
//  JSONContainer.cpp
//  remote_core
//
//  Created by David Moore on 11/1/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include "JSONContainer.hpp"
#include <iostream>
#include <fstream>

using json = nlohmann::json;
using namespace RemoteCore;

// MARK: - Initialization

JSONContainer::JSONContainer() {
    initializeForObject();
}

JSONContainer::JSONContainer(std::string payload) {
    internalContainer = json::parse(payload);
}

JSONContainer::JSONContainer(std::ifstream payloadStream) {
    internalContainer = json::parse(payloadStream);
}

void JSONContainer::initializeForObject() {
    internalContainer = json::object();
}

void JSONContainer::initializeForArray() {
    internalContainer = json::array();
}

// MARK: - Encoding

template <typename T>
void JSONContainer::setGenericValueForKey(T value, std::string key) {
    internalContainer[key] = value;
}

template <typename T>
void JSONContainer::emplaceGenericArray(std::vector<T> value) {
    // Insert the value after creating a JSON representation of it.
    json jsonValue(value);
    internalContainer.insert(internalContainer.end(), jsonValue.begin(), jsonValue.end());
}

std::unique_ptr<Container> JSONContainer::createNestedContainer() {
    return std::make_unique<JSONContainer>();
}

void JSONContainer::setNestedContainerForKey(std::unique_ptr<Container> nestedContainer, std::string key) {
    auto castNestedContainer = std::unique_ptr<JSONContainer>(static_cast<JSONContainer *>(nestedContainer.release()));
    internalContainer[key] = castNestedContainer->internalContainer;
}

void JSONContainer::addNestedContainers(std::vector<std::unique_ptr<Container>> nestedContainers) {
    for (auto &&nestedContainer : nestedContainers) {
        auto castNestedContainer = std::unique_ptr<JSONContainer>(static_cast<JSONContainer *>(nestedContainer.release()));
        internalContainer.push_back(castNestedContainer->internalContainer);
    }
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
    if (value.is_object() || value.is_array()) {
        auto container = std::make_unique<JSONContainer>(value.get<json>());
        return container;
    } else {
        return nullptr;
    }
}

template <typename T>
std::vector<T> JSONContainer::genericArray(void) {
    if (internalContainer.is_array()) {
        return internalContainer.get<std::vector<T>>();
    } else {
        return std::vector<T>();
    }
}

std::vector<std::unique_ptr<Container>> JSONContainer::containerArray(void) {
    std::vector<std::unique_ptr<Container>> containers;
    
    if (internalContainer.is_array()) {
        for (auto &value : internalContainer) {
            if (value.is_object()) {
                auto container = std::make_unique<JSONContainer>(value.get<json>());
                auto castContainer = std::unique_ptr<Container>(static_cast<Container *>(container.release()));
                containers.push_back(std::move(castContainer));
            }
        }
    }
    
    return containers;
}

// MARK: - Data Generation

std::string JSONContainer::generateData(void) {
    std::string payload(internalContainer.dump());
    return payload;
}
