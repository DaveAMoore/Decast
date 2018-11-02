//
//  JSONContainer.hpp
//  remote_core
//
//  Created by David Moore on 11/1/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#ifndef JSONContainer_hpp
#define JSONContainer_hpp

#include <iostream>
#include <nlohmann/json.hpp>
#include "Container.hpp"

namespace RemoteCore {
    class JSONContainer : public Container {
    private:
        std::string payload;
        
    public:
        JSONContainer() : payload(NULL) {};
        JSONContainer(std::string payload) : payload(payload) {};
    };
}

#endif /* JSONContainer_hpp */
