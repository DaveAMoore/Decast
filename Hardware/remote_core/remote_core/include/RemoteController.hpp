//
//  RemoteController.hpp
//  remote_core
//
//  Created by David Moore on 10/25/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#ifndef RemoteController_hpp
#define RemoteController_hpp

#include "ConnectionManager.hpp"

namespace RemoteCore {
    /// The base class for remote_core that should be used for remote-related functionality.
    class RemoteController {
    private:
        std::string serialNumber;
        
    protected:
        std::unique_ptr<ConnectionManager> connectionManager;
        
    public:
        RemoteController(const std::string &configFileRelativePath);
        
        /**
         Allows the controller to start managing a network connection and control hardware functionality.
         */
        void startController(void);
        
        /**
         Instructs the controller to disconnect from a current network connection and stop controlling hardware.
         */
        void stopController(void);
    };
}

#endif /* RemoteController_hpp */
