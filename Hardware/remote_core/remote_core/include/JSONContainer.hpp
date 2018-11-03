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
        nlohmann::json internalContainer;
        
    public:
        JSONContainer();
        JSONContainer(std::string payload);
        JSONContainer(nlohmann::json internalContainer) : internalContainer(internalContainer) {};
        
        ~JSONContainer() override {};
        
        void encodeIntForKey(int value, std::string key) override;
        void encodeBoolForKey(bool value, std::string key) override;
        void encodeStringForKey(std::string value, std::string key) override;
        
        std::unique_ptr<Container> requestEncodableContainer() override;
        void submitEncodableContainerForKey(std::unique_ptr<Container> encodableContainer, std::string key) override;
        
        int intForKey(std::string key) override;
        bool boolForKey(std::string key) override;
        std::string stringForKey(std::string key) override;
        std::unique_ptr<Container> containerForKey(std::string key) override;
    };
}

#endif /* JSONContainer_hpp */
