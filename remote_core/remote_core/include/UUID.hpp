//
//  UUID.hpp
//  remote_core
//
//  Created by David Moore on 11/6/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#ifndef UUID_hpp
#define UUID_hpp

#include <uuid/uuid.h>
#include <iostream>

namespace RemoteCore {
    class UUID {
    private:
        uuid_t uuid;
        
    public:
        UUID();
        
        /**
         String representation of the receiver.
         */
        std::string uuidString(void);
        
        /**
         Generates a universally unique identifier and returns the string representation.
         */
        static std::string GenerateUUIDString(void) {
            return UUID().uuidString();
        }
    };
}

#endif /* UUID_hpp */
