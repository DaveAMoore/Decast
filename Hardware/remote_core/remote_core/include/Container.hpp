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

namespace RemoteCore {
    class Container {
    public:
        virtual void encodeIntForKey(int value, std::string key) = 0;
        virtual void encodeBoolForKey(bool value, std::string key) = 0;
        virtual void encodeStringForKey(std::string value, std::string key) = 0;
        
        virtual int decodeIntForKey(std::string key) = 0;
        virtual bool decodeBoolForKey(std::string key) = 0;
        virtual std::string decodeStringForKey(std::string key) = 0;
    };
}

#endif /* Container_hpp */
