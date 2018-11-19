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
    class RemoteController : public TrainingSessionDelegate {
    private:
        std::string userID;
        
    protected:
        std::unique_ptr<ConnectionManager> connectionManager;
        std::unique_ptr<HardwareController> hardwareController;
        std::shared_ptr<TrainingSession> trainingSession;
    
        /**
         Subscribes to the default device topic. The topic format is 'remote_core/account/<user id>/<serial number>'.
         */
        void subscribeToDefaultTopic(void);
        
        /**
         Handles the message that was received.
         */
        void handleMessage(std::unique_ptr<Message> message);
        
        /**
         Handles the command message that was received.
         */
        void handleCommandMessage(std::unique_ptr<Message> message);
        
        /**
         Handles the training message that was received.
         */
        void handleTrainingMessage(std::unique_ptr<Message> message);
        
        /**
         Handles the response message that was received.
         */
        void handleResponseMessage(std::unique_ptr<Message> message);
        
        /**
         Attempts to send a message on the default topic.

         @param message The message that will be sent.
         */
        void sendMessage(std::unique_ptr<Message> message);
        
        /**
         Sends a training message by referencing data from a particular session.

         @param session The training session the message is being sent for.
         @param command Command that is associated with the message.
         @param directive Directive to be sent with the message.
         */
        void sendTrainingMessageForSession(TrainingSession *session, Command *command, std::string directive);
        
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
        
        // The training session is beginning.
        void trainingSessionDidBegin(TrainingSession *session) override;
        
        // A fatal error occurred cuasing the training session to fail entirely.
        void trainingSessionDidFailWithError(TrainingSession *session, Error error) override;
        
        // The training session is going to begin learning the command.
        void trainingSessionWillLearnCommand(TrainingSession *session, Command command) override;
        void trainingSessionDidLearnCommand(TrainingSession *session, Command command) override;
        
        // Inclusive arbitrary input indicates all buttons should be pressed – in no specific order (i.e., arbitrary).
        void trainingSessionDidRequestInclusiveArbitraryInput(TrainingSession *session) override;
        
        // Input should be provided for a single command, that is the one that is passed as a parameter.
        void trainingSessionDidRequestInputForCommand(TrainingSession *session, Command command) override;
        
        // Exclusive arbitrary input indicates that a single arbitrary command (i.e., button) should be pressed
        void trainingSessionDidRequestExclusiveArbitraryInput(TrainingSession *session) override;
    };
}

#endif /* RemoteController_hpp */
