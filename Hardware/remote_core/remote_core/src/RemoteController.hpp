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

namespace remote_core {
    /// The base class for remote_core that should be used for remote-related functionality.
    class RemoteController {
    private:
        
    protected:
        std::unique_ptr<ConnectionManager> connectionManager;
        
    public:
        RemoteController();
        
        void startController(void);
        void stopController(void);
    };
}

#endif /* RemoteController_hpp */
