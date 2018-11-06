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
        
    protected:
        std::unique_ptr<Container> createNestedContainer() override;
        void setNestedContainerForKey(std::unique_ptr<Container> nestedContainer, std::string key) override;
        
    public:
        JSONContainer();
        JSONContainer(std::string payload);
        JSONContainer(nlohmann::json internalContainer) : internalContainer(internalContainer) {};
        
        ~JSONContainer() override {};
        
        std::unique_ptr<uint8_t> generateData(size_t &length) override;
        
        void setIntForKey(int value, std::string key) override;
        void setUnsignedIntForKey(unsigned int value, std::string key) override;
        void setFloatForKey(double value, std::string key) override;
        void setBoolForKey(bool value, std::string key) override;
        void setStringForKey(std::string value, std::string key) override;
        
        int intForKey(std::string key) override;
        unsigned int unsignedIntForKey(std::string key) override;
        double floatForKey(std::string key) override;
        bool boolForKey(std::string key) override;
        std::string stringForKey(std::string key) override;
        std::unique_ptr<Container> containerForKey(std::string key) override;
    };
}

#endif /* JSONContainer_hpp */
