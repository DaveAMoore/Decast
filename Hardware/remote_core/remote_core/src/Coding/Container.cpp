//
//  Container.cpp
//  remote_core
//
//  Created by David Moore on 11/3/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include "Container.hpp"
#include <algorithm>
#include <stdexcept>

using namespace RemoteCore;

std::unique_ptr<Container> Container::requestNestedContainer() {
    auto nestedContainer = createNestedContainer();
    nestedContainers.push_back(nestedContainer.get());
    
    return nestedContainer;
}

void Container::submitNestedContainerForKey(std::unique_ptr<Container> nestedContainer, std::string key) {
    auto position = std::find_if(nestedContainers.begin(), nestedContainers.end(), [&](Container *container) {
        return container == nestedContainer.get();
    });
    
    if (position == nestedContainers.end()) {
        throw std::invalid_argument("Expected 'nestedContainer' to be registered with the receiver.");
    }
    
    nestedContainers.erase(position);
    setNestedContainerForKey(std::move(nestedContainer), key);
}

void Container::deleteNestedContainer(std::unique_ptr<Container> nestedContainer) {
    auto position = std::find_if(nestedContainers.begin(), nestedContainers.end(), [&](Container *container) {
        return container == nestedContainer.get();
    });
    
    if (position == nestedContainers.end()) {
        throw std::invalid_argument("Expected 'nestedContainer' to be registered with the receiver.");
    }
    
    nestedContainers.erase(position);
}
