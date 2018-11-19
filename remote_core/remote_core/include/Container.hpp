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
#include <vector>

namespace RemoteCore {
    class Container {
    private:
        std::vector<Container *> nestedContainers;
        
    protected:
        virtual std::unique_ptr<Container> createNestedContainer() = 0;
        virtual void setNestedContainerForKey(std::unique_ptr<Container> nestedContainer, std::string key) = 0;
        virtual void addNestedContainers(std::vector<std::unique_ptr<Container>> nestedContainers) = 0;
        
    public:
        
        // MARK: - Initialization
        
        virtual void initializeForObject(void) = 0;
        virtual void initializeForArray(void) = 0;
        
        // MARK: - Deinitialization
        
        virtual ~Container() {};
        
        // MARK: - Setters
        
        virtual void setIntForKey(int value, std::string key) = 0;
        virtual void setUnsignedIntForKey(unsigned int value, std::string key) = 0;
        virtual void setFloatForKey(double value, std::string key) = 0;
        virtual void setBoolForKey(bool value, std::string key) = 0;
        virtual void setStringForKey(std::string value, std::string key) = 0;
        
        virtual void emplaceArray(std::vector<int> value) = 0;
        virtual void emplaceArray(std::vector<unsigned int> value) = 0;
        virtual void emplaceArray(std::vector<double> value) = 0;
        virtual void emplaceArray(std::vector<bool> value) = 0;
        virtual void emplaceArray(std::vector<std::string> value) = 0;
        
        // MARK: - Getters
        
        virtual int intForKey(std::string key) = 0;
        virtual unsigned int unsignedIntForKey(std::string key) = 0;
        virtual double floatForKey(std::string key) = 0;
        virtual bool boolForKey(std::string key) = 0;
        virtual std::string stringForKey(std::string key) = 0;
        virtual std::unique_ptr<Container> containerForKey(std::string key) = 0;
        
        virtual std::vector<int> intArray(void) = 0;
        virtual std::vector<unsigned int> unsignedIntArray(void) = 0;
        virtual std::vector<double> floatArray(void) = 0;
        virtual std::vector<bool> boolArray(void) = 0;
        virtual std::vector<std::string> stringArray(void) = 0;
        virtual std::vector<std::unique_ptr<Container>> containerArray(void) = 0;
        
        // MARK: - Nested Container Management
        
        /**
         Requests a container that will be registered with the receiver, which may then be used for arbitrary data containment.
         
         When a container is requested, ownership is granted to the caller. The lifecycle for a nested container ends once the container is submitted to the receiver or deleted by the receiver. Once a nested container is submitted, it's ownership is transfered and relinquished when appropriate. If a nested container is not submitted for any reason, it is important that the container at least be deleted by calling 'deleteNestedContainer(nestedContainer)'.
         
         @return Unique ownership for a container of some type derivative of Container.
         */
        std::unique_ptr<Container> requestNestedContainer(bool isArray = false);
        
        /**
         Injects the nested container into the receiver's container. Providing a container that is not registered with the receiver is considered an exception, and one will be thrown accordingly.
         
         Once a container has been submitted, it's lifecycle is complete and ownership relinquished.
         
         @param nestedContainer Container that was retrieved through a call to 'requestNestedContainer()' previously.
         @param key Key for which the nested container will be submitted under. You may retrieve the encoded container at a later point in time using this key.
         */
        void submitNestedContainerForKey(std::unique_ptr<Container> nestedContainer, std::string key);
        
        /**
         Injects the nested container into the receiver's container. Providing a container that is not registered with the receiver is considered invalid input, and an exception will be thrown accordingly.
         
         Ownership/lifecycle semantics are respected according to other related nested container submission methods.
         
         @warning This method is intended for use with – and only with – array containers.
         @param nestedContainer Container that was previously retrieved through a call to 'requestNestedContainer()'.
         */
        void submitNestedContainer(std::unique_ptr<Container> nestedContainer);
        
        /**
         Injects the array of nested containers into the receiver's container. Providing an array of containers that have not been registered with the receiver is considered an exception, and one will be thrown accordingly.
         
         Once the array of nested containers have been submitted, all of the containers' lifecycles are complete and onwership of each is relinquished.

         @param nestedContainers Containers that were retrieved through repeated calls to 'requestNestedContainer()'.
         */
        void submitNestedContainers(std::vector<std::unique_ptr<Container>> nestedContainers);
        
        /**
         Removes a particular nested container from the receiver's registration system for nested containers.
         */
        void deleteNestedContainer(std::unique_ptr<Container> nestedContainer);
        
        // MARK: - Data Generation
        
        /**
         Generates the data the receiver has been storing. The container will transfer ownership of the data to the caller.
         
         @param length Reference to a 'size_t' instance that will be updated with the correct length of the data.
         @return Unique pointer to the first byte of data.
         */
        virtual std::string generateData(void) = 0;
    };
}

#endif /* Container_hpp */
