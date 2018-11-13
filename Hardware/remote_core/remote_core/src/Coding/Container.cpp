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

std::unique_ptr<Container> Container::requestNestedContainer(bool isArray) {
    auto nestedContainer = createNestedContainer();
    nestedContainers.push_back(nestedContainer.get());
    
    if (isArray) {
        nestedContainer->initializeForArray();
    }
    
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

void Container::submitNestedContainer(std::unique_ptr<Container> nestedContainer) {
    auto position = std::find_if(nestedContainers.begin(), nestedContainers.end(), [&](Container *container) {
        return container == nestedContainer.get();
    });
    
    if (position == nestedContainers.end()) {
        throw std::invalid_argument("Expected 'nestedContainer' to be registered with the receiver.");
    }
    
    nestedContainers.erase(position);
    
    std::vector<std::unique_ptr<Container>> containers;
    containers.push_back(std::move(nestedContainer));
    addNestedContainers(std::move(containers));
}

void Container::submitNestedContainers(std::vector<std::unique_ptr<Container>> containers) {
    // Take all of the containers and get raw pointers for them.
    std::vector<Container *> containerPtrs;
    for (auto &&container : containers) {
        containerPtrs.push_back(container.get());
    }
    
    // Create a lambda to compare pointers.
    auto pointerComparator = [](Container *lhs, Container *rhs) {
        return (uint64_t)lhs > (uint64_t)rhs;
    };
    
    // Sort each of the vectors of pointers.
    std::sort(containerPtrs.begin(), containerPtrs.end(), pointerComparator);
    std::sort(nestedContainers.begin(), nestedContainers.end(), pointerComparator);
    
    // Create a comparator for sets.
    auto setComparator = [](Container *lhs, Container *rhs) {
        return lhs == rhs;
    };
    
    // Find the intersection of the pointers.
    std::vector<Container *> intersection;
    std::set_intersection(containerPtrs.begin(),
                          containerPtrs.end(),
                          nestedContainers.begin(),
                          nestedContainers.end(),
                          intersection.begin(),
                          setComparator);
    
    // Determine if the intersection is equal to the proper size.
    if (intersection.size() != containerPtrs.size()) {
        throw std::invalid_argument("Expected all 'containers' to be registered with the receiver.");
    }
    
    // Compute the set-difference.
    std::vector<Container *> difference;
    std::set_difference(containerPtrs.begin(),
                        containerPtrs.end(),
                        nestedContainers.begin(),
                        nestedContainers.end(),
                        difference.begin(),
                        setComparator);
    
    // Copy the difference to the nested containers.
    nestedContainers = difference;
    
    // Add the nested containers.
    addNestedContainers(std::move(containers));
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
