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
#include <vector>
#include "Container.hpp"

namespace RemoteCore {
    class Coding;
    
    class Coder final {
    private:
        std::unique_ptr<Container> codingContainer;
        
    public:
        Coder(std::unique_ptr<Container> codingContainer) : codingContainer(std::move(codingContainer)) {};
        
        // MARK: - Primitive Encoding
        
        void encodeIntForKey(int value, std::string key);
        void encodeUnsignedIntForKey(unsigned int value, std::string key);
        void encodeFloatForKey(double value, std::string key);
        void encodeBoolForKey(bool value, std::string key);
        void encodeStringForKey(std::string value, std::string key);
        void encodeObjectForKey(const Coding *object, std::string key);
        
        template <class T>
        void encodeArrayForKey(std::vector<T> value, std::string key) {
            static_assert(true, "'encodeArrayForKey' not implemented.");
        }
        
        // MARK: - Primitive Decoding
        
        int decodeIntForKey(std::string key) const;
        unsigned int decodeUnsignedIntForKey(std::string key) const;
        double decodeFloatForKey(std::string key) const;
        bool decodeBoolForKey(std::string key) const;
        std::string decodeStringForKey(std::string key) const;
        
        /**
         Decodes an object of some type that conforms to 'Coding', relying on the generic template parameter T.

         @param key The key with which the object was encoded to originally.
         @return A decoded object.
         */
        template <typename T>
        std::unique_ptr<T> decodeObjectForKey(std::string key) const {
            static_assert(std::is_default_constructible<T>::value,
                          "expected template parameter to be default constructable");
            static_assert(std::is_base_of<Coding, T>::value,
                          "expected template parameter to be a derived type of 'Coding'");
            
            // Retrieve a container from the coding container.
            auto container = codingContainer->containerForKey(key);
            
            // Check if the container existed.
            if (container == nullptr) {
                return nullptr;
            }
            
            auto aCoder = std::make_unique<Coder>(std::move(container));
            
            // Create the object using the coder based on the decoded container.
            auto object = std::make_unique<T>();
            object->decodeWithCoder(aCoder.get());
            
            return object;
        }
        
        template <class T>
        std::vector<T> decodeArrayForKey(std::string key) const {
            static_assert(true, "'decodeArrayForKey' not implemented.");
            return std::vector<T>();
        }
        
        /**
         Encodes the provided object at the root of the container.
         */
        void encodeRootObject(const Coding *object);
        
        /**
         Decodes the object that is at the base of the coding container.

         @return The decoded root object from the coding container.
         */
        template <typename T>
        std::unique_ptr<T> decodeRootObject(void) const {
            static_assert(std::is_default_constructible<T>::value,
                          "expected template parameter to be default constructable");
            static_assert(std::is_base_of<Coding, T>::value,
                          "expected template parameter to be a derived type of 'Coding'");
            
            // Create the object using the coder based on the decoded container.
            auto object = std::make_unique<T>();
            object->decodeWithCoder(this);
            
            return object;
        }
        
        /**
         Invalidates the coder by transferring ownership of the 'codingContainer' to the caller. Once a coder is invalidated it is undefined to continue using it.

         @return The internal container that was used for encoding/decoding.
         */
        std::unique_ptr<Container> invalidateCoder(void) {
            return std::move(codingContainer);
        }
    };
}

#endif /* Coder_hpp */
