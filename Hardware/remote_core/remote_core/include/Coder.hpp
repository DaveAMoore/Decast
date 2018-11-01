//
//  Coder.hpp
//  remote_core
//
//  Created by David Moore on 10/31/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#ifndef Coder_hpp
#define Coder_hpp

#include <iostream>
#include <memory>
#include <rapidjson/document.h>
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"

namespace RemoteCore {
    class Coding;
    
    class Coder final {
    private:
    public:
        Coder();
        
        void encodeIntForKey(int value, std::string key);
        void encodeBoolForKey(bool value, std::string key);
        void encodeStringForKey(std::string value, std::string key);
        void encodeObjectForKey(const Coding &object, std::string key);
        
        int decodeIntForKey(std::string key);
        bool decodeBoolForKey(std::string key);
        std::string decodeStringForKey(std::string key);
        
        template <typename T>
        std::unique_ptr<T> decodeObjectForKey(std::string key) {
            static_assert(std::is_default_constructible<T>::value,
                          "expected template parameter to be default constructable");
            static_assert(std::is_base_of<Coding, T>::value,
                          "expected template parameter to be a derived type of 'SecureCoding'");
            
            auto object = std::make_unique<T>();
            object->decodeWithCoder(this);
            
            return object;
        }
    };
}

#endif /* Coder_hpp */
