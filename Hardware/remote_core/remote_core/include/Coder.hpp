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
#include "static_logic.hpp"
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
        
        // MARK: - Primitive Decoding
        
        int decodeIntForKey(std::string key) const;
        unsigned int decodeUnsignedIntForKey(std::string key) const;
        double decodeFloatForKey(std::string key) const;
        bool decodeBoolForKey(std::string key) const;
        std::string decodeStringForKey(std::string key) const;
        
        // MARK: - Object Encoding
        
        /**
         Encodes the provided object at the root of the container.
         */
        void encodeRootObject(const Coding *object);
        
        // MARK: - Object Decoding
        
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
        
        // MARK: - Array Encoding
        
        template <typename T>
        void encodeRootArray(std::vector<T> value) {
            // Produce integral constants for static_assert and static_if later.
            std::integral_constant<bool, std::is_same<int, T>::value> isInt;
            std::integral_constant<bool, std::is_same<unsigned int, T>::value> isUnsignedInt;
            std::integral_constant<bool, std::is_same<double, T>::value> isFloat;
            std::integral_constant<bool, std::is_same<bool, T>::value> isBool;
            std::integral_constant<bool, std::is_same<std::string, T>::value> isString;
            std::integral_constant<bool, isInt || isUnsignedInt || isFloat || isBool || isString> isPrimitive;
            std::integral_constant<bool, std::is_base_of<Coding, T>::value> isCoding;
            
            /*logic::static_if<!isPrimitive && !isCoding>([]() {
                typedef typename std::remove_reference<decltype(*std::declval<T>())>::type U;
                //std::integral_constant<bool, std::is_same<Coding, U>::value> isCodingPointer;
                
                //static_assert(isCodingPointer, "");
            }, [&]() {
                // Assert that at least one of the above conditions were met.
                static_assert(isPrimitive || isCoding, "expected type T to be primitive or conform to Coding");
            });*/
            
            // typedef typename std::remove_reference<decltype(*std::declval<T>())>::type U;
            
            
            // typedef typename std::is_base_of<Coding, std::remove_reference<decltype(*std::declval<T>())>::type> U;
            //std::integral_constant<bool, std::is_same<Coding, U>::value> isCodingPointer;
            std::integral_constant<bool, false> isCodingPointer;
            
            // Assert that at least one of the above conditions were met.
            static_assert(isPrimitive || isCoding || isCodingPointer, "expected type T to be primitive or conform to Coding");
            
            // Initialize the container for an array.
            codingContainer->initializeForArray();
            
            // Emplace an array of primitive values.
            logic::static_if<isPrimitive>([&](auto &primitiveValue) {
                codingContainer->emplaceArray(primitiveValue);
            })(value);
            
            // Encode the array of objects.
            logic::static_if<isCoding || isCodingPointer>([&](auto &array) {
                for (auto element : array) {
                    // Encode the element to a nested container.
                    auto nestedObjectContainer = codingContainer->requestNestedContainer();
                    auto aCoder = std::make_unique<Coder>(std::move(nestedObjectContainer));
                    
                    // Encode the root object, properly passing in a pointer.
                    logic::static_if<isCoding>([&](auto &codingValue) {
                        aCoder->encodeRootObject(&codingValue);
                    })(element);
                    
                    // Use the pointer to encode the object.
                    logic::static_if<isCodingPointer>([&](auto &codingValue) {
                        aCoder->encodeRootObject(codingValue);
                    })(element);
                    
                    // Submit the nested container.
                    codingContainer->submitNestedContainer(aCoder->invalidateCoder());
                }
            })(value);
        }
        
        template <typename T>
        void encodeArrayForKey(std::vector<T> value, std::string key) {
            /*// Produce integral constants for static_assert and static_if later.
            std::integral_constant<bool, std::is_same<int, T>::value> isInt;
            std::integral_constant<bool, std::is_same<unsigned int, T>::value> isUnsignedInt;
            std::integral_constant<bool, std::is_same<double, T>::value> isFloat;
            std::integral_constant<bool, std::is_same<bool, T>::value> isBool;
            std::integral_constant<bool, std::is_same<std::string, T>::value> isString;
            std::integral_constant<bool, isInt || isUnsignedInt || isFloat || isBool || isString> isPrimitive;
            std::integral_constant<bool, std::is_base_of<Coding, T>::value> isCoding;
            std::integral_constant<bool, std::is_base_of<const Coding *, T>::value> isCodingPointer;
        
            // Assert that at least one of the above conditions were met.
            static_assert(isPrimitive || isCoding || isCodingPointer, "expected type T to be primitive or conform to Coding");*/
            
            // Request a nested container.
            auto nestedContainer = codingContainer->requestNestedContainer(true);
            auto aCoder = std::make_unique<Coder>(std::move(nestedContainer));
            
            // Encode the array.
            aCoder->encodeRootArray(value);
            
            // Submit the array container.
            codingContainer->submitNestedContainerForKey(aCoder->invalidateCoder(), key);
            
            // Emplace an array of primitive values.
            /* logic::static_if<isPrimitive>([&](auto &primitiveValue) {
                nestedContainer->emplaceArray(primitiveValue);
            })(value);
            
            // Encode the array of objects.
            logic::static_if<isCoding || isCodingPointer>([&]() {
                std::vector<std::unique_ptr<Container>> nestedContainers;
                
                for (auto element : value) {
                    // Encode the element to a nested container.
                    auto nestedObjectContainer = nestedContainer->requestNestedContainer();
                    auto aCoder = std::make_unique<Coder>(std::move(nestedObjectContainer));
                    
                    // Encode the root object, properly passing in a pointer.
                    logic::static_if<isCoding>([&](auto &codingValue) {
                        aCoder->encodeRootObject(&codingValue);
                    })(element);
                    
                    // Use the pointer to encode the object.
                    logic::static_if<isCodingPointer>([&](auto &codingValue) {
                        aCoder->encodeRootObject(codingValue);
                    })(element);
                    
                    // Collect the nested container.
                    nestedContainers.push_back(aCoder->invalidateCoder());
                }
                
                nestedContainer->submitNestedContainers(std::move(nestedContainers));
            });
            
            // Submit the nested container (i.e., array).
            codingContainer->submitNestedContainerForKey(std::move(nestedContainer), key); */
        }
        
        // MARK: - Array Decoding
        
        template <typename T>
        std::vector<T> decodeRootArray(void) const {
            // Produce integral constants for static_assert and static_if later.
            std::integral_constant<bool, std::is_same<int, T>::value> isInt;
            std::integral_constant<bool, std::is_same<unsigned int, T>::value> isUnsignedInt;
            std::integral_constant<bool, std::is_same<double, T>::value> isFloat;
            std::integral_constant<bool, std::is_same<bool, T>::value> isBool;
            std::integral_constant<bool, std::is_same<std::string, T>::value> isString;
            std::integral_constant<bool, isInt || isUnsignedInt || isFloat || isBool || isString> isPrimitive;
            std::integral_constant<bool, std::is_base_of<Coding, T>::value> isCoding;
            
            std::integral_constant<bool, std::is_base_of<std::unique_ptr<Coding>, T>::value> isCodingPointer;
            //std::unique_ptr<Foo>::element_type>::value
            
            // Assert that at least one of the above conditions were met.
            static_assert(isPrimitive || isCoding || isCodingPointer, "expected type T to be primitive or conform to Coding");
            
            // Initialize an empty vector to start.
            std::vector<T> value;
            
            logic::static_if<isInt>([&](auto &array) {
                array = codingContainer->intArray();
            })(value);
            
            logic::static_if<isUnsignedInt>([&](auto &array) {
                array = codingContainer->unsignedIntArray();
            })(value);
            
            logic::static_if<isFloat>([&](auto &array) {
                array = codingContainer->floatArray();
            })(value);
            
            logic::static_if<isBool>([&](auto &array) {
                array = codingContainer->boolArray();
            })(value);
            
            logic::static_if<isString>([&](auto &array) {
                array = codingContainer->stringArray();
            })(value);
            
            logic::static_if<isCoding>([&](auto &val) {
                auto containerArray = codingContainer->containerArray();
                for (auto &&container : containerArray) {
                    auto aCoder = std::make_unique<Coder>(std::move(container));
                    /*auto object = aCoder->decodeRootObject<typeof(T)>();
                    array.push_back(object);*/
                    
                    
                    logic::static_if<isCoding>([&](auto &array) {
                        std::unique_ptr<T> rootObject = aCoder->decodeRootObject<T>();
                        //T object(&ootObject.release());
                        
                        //array.push_back(object);
                    })(val);
                    
                    logic::static_if<isCodingPointer>([&](auto &array) {
                        auto object = aCoder->decodeRootObject<typeof(T)>();
                        array.push_back(object);
                    })(val);
                }
            })(value);
            
            return value;
        }
        
        template <class T>
        std::vector<T> decodeArrayForKey(std::string key) const {
            auto nestedContainer = codingContainer->containerForKey(key);
            auto aCoder = std::make_unique<Coder>(std::move(nestedContainer));
            
            return aCoder->decodeRootArray<T>();
            
            /*
            // Produce integral constants for static_assert and static_if later.
            std::integral_constant<bool, std::is_same<int, T>::value> isInt;
            std::integral_constant<bool, std::is_same<unsigned int, T>::value> isUnsignedInt;
            std::integral_constant<bool, std::is_same<double, T>::value> isFloat;
            std::integral_constant<bool, std::is_same<bool, T>::value> isBool;
            std::integral_constant<bool, std::is_same<std::string, T>::value> isString;
            std::integral_constant<bool, isInt || isUnsignedInt || isFloat || isBool || isString> isPrimitive;
            std::integral_constant<bool, std::is_base_of<Coding, T>::value> isCoding;
            std::integral_constant<bool, std::is_base_of<std::unique_ptr<Coding>, T>::value> isCodingPointer;
            
            // Assert that at least one of the above conditions were met.
            static_assert(isPrimitive || isCoding || isCodingPointer, "expected type T to be primitive or conform to Coding");
            
            // Initialize an empty vector to start.
            std::vector<T> value;
            
            logic::static_if<isInt>([&](auto &array) {
                array = codingContainer->intArray();
            })(value);
            
            logic::static_if<isUnsignedInt>([&](auto &array) {
                array = codingContainer->unsignedIntArray();
            })(value);
            
            logic::static_if<isFloat>([&](auto &array) {
                array = codingContainer->floatArray();
            })(value);
            
            logic::static_if<isBool>([&](auto &array) {
                array = codingContainer->boolArray();
            })(value);
            
            logic::static_if<isString>([&](auto &array) {
                array = codingContainer->stringArray();
            })(value);
            
            logic::static_if<isCoding || isCodingPointer>([&]() {
                auto container = codingContainer->containerForKey(key);

                logic::static_if<isCoding>([&](auto &array) {
                    
                })(value);
                
                logic::static_if<isCodingPointer>([&](auto &array) {
                    array = container->containerArray();
                })(value);
            });
            
            return value;*/
        }
        
        // MARK: - Invalidation
        
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
