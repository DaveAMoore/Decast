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
#include "HardwareController.hpp"
#include "Message.hpp"

namespace RemoteCore {
    /// The base class for remote_core that should be used for remote-related functionality.
    class RemoteController {
    private:
        std::string userID;
        
    protected:
        std::unique_ptr<ConnectionManager> connectionManager;
        std::unique_ptr<HardwareController> hardwareController;
    
        /**
         Subscribes to the default device topic. The topic format is 'remote_core/account/<user id>/<serial number>'.
         */
        void subscribeToDefaultTopic(void);
        
        /**
         Handles the message that was received.
         */
        void handleMessage(std::unique_ptr<Message> message);
        
        /**
         Attempts to send a message on the default topic.

         @param message The message that will be sent.
         */
        void sendMessage(std::unique_ptr<Message> message);
        
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
