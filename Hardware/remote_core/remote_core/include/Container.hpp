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
        
    public:
        virtual ~Container() {};
        
        virtual void setIntForKey(int value, std::string key) = 0;
        virtual void setUnsignedIntForKey(unsigned int value, std::string key) = 0;
        virtual void setFloatForKey(double value, std::string key) = 0;
        virtual void setBoolForKey(bool value, std::string key) = 0;
        virtual void setStringForKey(std::string value, std::string key) = 0;
        
        virtual int intForKey(std::string key) = 0;
        virtual unsigned int unsignedIntForKey(std::string key) = 0;
        virtual double floatForKey(std::string key) = 0;
        virtual bool boolForKey(std::string key) = 0;
        virtual std::string stringForKey(std::string key) = 0;
        virtual std::unique_ptr<Container> containerForKey(std::string key) = 0;
        
        /**
         Requests a container that will be registered with the receiver, which may then be used for arbitrary data containment.
         
         When a container is requested, ownership is granted to the callee. The lifecycle for a nested container ends once the container is submitted to the receiver or deleted by the receiver. Once a nested container is submitted, it's ownership is transfered and relinquished when appropriate. If a nested container is not submitted for any reason, it is important that the container at least be deleted by calling 'deleteNestedContainer(nestedContainer)'.
         
         @return Unique ownership for a container of some type derivative of Container.
         */
        std::unique_ptr<Container> requestNestedContainer();
        
        /**
         Injects the nested container into the receiver's container. Providing a container that is not registered with the receiver is considered an exception, and one will be thrown accordingly.
         
         Once a container has been submitted, it's lifecycle is complete and ownership relinquished.
         
         @param nestedContainer Container that was retrieved through a call to 'requestNestedContainer()' previously.
         @param key Key for which the nested container will be submitted under. You may retrieve the encoded container at a later point in time using this key.
         */
        void submitNestedContainerForKey(std::unique_ptr<Container> nestedContainer, std::string key);
        
        /**
         Removes a particular nested container from the receiver's registration system for nested containers.
         */
        void deleteNestedContainer(std::unique_ptr<Container> nestedContainer);
    };
}

#endif /* Container_hpp */
