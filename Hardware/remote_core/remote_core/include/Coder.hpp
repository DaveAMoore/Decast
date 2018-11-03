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
#include "Container.hpp"

namespace RemoteCore {
    class Coding;
    
    class Coder final {
    private:
        std::unique_ptr<Container> codingContainer;
        
    public:
        Coder(std::unique_ptr<Container> codingContainer) : codingContainer(std::move(codingContainer)) {};
        
        void encodeIntForKey(int value, std::string key);
        void encodeBoolForKey(bool value, std::string key);
        void encodeStringForKey(std::string value, std::string key);
        void encodeObjectForKey(const Coding &object, std::string key);
        
        int decodeIntForKey(std::string key);
        bool decodeBoolForKey(std::string key);
        std::string decodeStringForKey(std::string key);
        
        /**
         Decodes an object of some type that conforms to 'Coding', relying on the generic template parameter T.

         @param key The key with which the object was encoded to originally.
         @return A decoded object.
         */
        template <typename T>
        std::unique_ptr<T> decodeObjectForKey(std::string key) {
            static_assert(std::is_default_constructible<T>::value,
                          "expected template parameter to be default constructable");
            static_assert(std::is_base_of<Coding, T>::value,
                          "expected template parameter to be a derived type of 'SecureCoding'");
            
            // Retrieve a container from the coding container.
            auto container = codingContainer->containerForKey(key);
            auto aCoder = std::make_unique<Coder>(std::move(container));
            
            // Create the object using the coder based on the decoded container.
            auto object = std::make_unique<T>();
            object->decodeWithCoder(aCoder.get());
            
            return object;
        }
    };
}

#endif /* Coder_hpp */
