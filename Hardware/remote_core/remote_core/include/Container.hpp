//
//  Container.hpp
//  remote_core
//
//  Created by David Moore on 11/1/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#ifndef Container_hpp
#define Container_hpp

#include <iostream>
#include <memory>

namespace RemoteCore {
    class Container {
    public:
        virtual ~Container() {};
        
        virtual void encodeIntForKey(int value, std::string key) = 0;
        virtual void encodeBoolForKey(bool value, std::string key) = 0;
        virtual void encodeStringForKey(std::string value, std::string key) = 0;
        
        virtual std::unique_ptr<Container> requestEncodableContainer() = 0;
        virtual void submitEncodableContainerForKey(std::unique_ptr<Container> encodableContainer,
                                                    std::string key) = 0;
        
        virtual int intForKey(std::string key) = 0;
        virtual bool boolForKey(std::string key) = 0;
        virtual std::string stringForKey(std::string key) = 0;
        virtual std::unique_ptr<Container> containerForKey(std::string key) = 0;
    };
}

#endif /* Container_hpp */
