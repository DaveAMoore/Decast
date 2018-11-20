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
#include <fstream>
#include "nlohmann/json.hpp"
#include "Container.hpp"

namespace RemoteCore {
    class JSONContainer : public Container {
    private:
        nlohmann::json internalContainer;
        
        template <typename T>
        void setGenericValueForKey(T value, std::string key);
        
        template <typename T>
        void emplaceGenericArray(std::vector<T> value);
        
        template <typename T>
        std::vector<T> genericArray(void);
        
    protected:
        std::unique_ptr<Container> createNestedContainer() override;
        void setNestedContainerForKey(std::unique_ptr<Container> nestedContainer, std::string key) override;
        void addNestedContainers(std::vector<std::unique_ptr<Container>> nestedContainers) override;
        
    public:
        JSONContainer();
        JSONContainer(std::string payload);
        JSONContainer(std::ifstream payloadStream);
        JSONContainer(nlohmann::json internalContainer) : internalContainer(internalContainer) {};
        
        ~JSONContainer() override {};
        
        void initializeForObject(void) override;
        void initializeForArray(void) override;
        
        void setIntForKey(int value, std::string key) override { setGenericValueForKey(value, key); }
        void setUnsignedIntForKey(unsigned int value, std::string key) override { setGenericValueForKey(value, key); }
        void setFloatForKey(double value, std::string key) override { setGenericValueForKey(value, key); }
        void setBoolForKey(bool value, std::string key) override { setGenericValueForKey(value, key); }
        void setStringForKey(std::string value, std::string key) override { setGenericValueForKey(value, key); }
        
        void emplaceArray(std::vector<int> value) override { emplaceGenericArray(value); }
        void emplaceArray(std::vector<unsigned int> value) override { emplaceGenericArray(value); }
        void emplaceArray(std::vector<double> value) override { emplaceGenericArray(value); }
        void emplaceArray(std::vector<bool> value) override { emplaceGenericArray(value); }
        void emplaceArray(std::vector<std::string> value) override { emplaceGenericArray(value); }
        
        int intForKey(std::string key) override;
        unsigned int unsignedIntForKey(std::string key) override;
        double floatForKey(std::string key) override;
        bool boolForKey(std::string key) override;
        std::string stringForKey(std::string key) override;
        std::unique_ptr<Container> containerForKey(std::string key) override;
        
        std::vector<int> intArray(void) override { return genericArray<int>(); }
        std::vector<unsigned int> unsignedIntArray(void) override { return genericArray<unsigned int>(); }
        std::vector<double> floatArray(void) override { return genericArray<double>(); }
        std::vector<bool> boolArray(void) override { return genericArray<bool>(); }
        std::vector<std::string> stringArray(void) override { return genericArray<std::string>(); }
        std::vector<std::unique_ptr<Container>> containerArray(void) override;
        
        std::string generateData(void) override;
    };
}

#endif /* JSONContainer_hpp */
