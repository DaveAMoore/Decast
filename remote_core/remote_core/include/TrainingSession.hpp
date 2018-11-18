//
//  TrainingSession.hpp
//  remote_core
//
//  Created by David Moore on 11/5/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#ifndef TrainingSession_hpp
#define TrainingSession_hpp

#include <iostream>
#include <memory>
#include "Remote.hpp"
#include "Error.hpp"

namespace RemoteCore {
    class HardwareController;
    class TrainingSessionDelegate;
    
    class TrainingSession {
    private:
        std::string sessionID;
        Remote associatedRemote;
        std::weak_ptr<TrainingSessionDelegate> delegate;
        Command currentCommand;
        std::vector<std::string> availableCommandIDs;
        
    public:
        TrainingSession(Remote associatedRemote);
        
        std::string getSessionID(void) {
            return sessionID;
        }
        
        std::weak_ptr<TrainingSessionDelegate> getDelegate(void) {
            return delegate;
        }
        
        void setDelegate(std::weak_ptr<TrainingSessionDelegate> delegate) {
            this->delegate = delegate;
        }
        
        /**
         Initializes a new training session. This will require user input (e.g., inclusive arbitrary input).
         */
        void startTrainingSession(void);
        
        /**
         Creates the representation of a new command with the given localized title. The localized title provided may be an empty string.
         */
        Command createCommandWithLocalizedTitle(std::string localizedTitle);
        
        /**
         Starts the training process for a specific command. Note that the receiver does not determine if the command is a repeat or not. (Asynchronous)
         
         @param command The command that will be learnt. The localized title is persisted when reporting the status of this call, but it will not be modified.
         */
        void learnCommand(Command command);
    };
    
    class TrainingSessionDelegate {
    public:
        // The training session is beginning.
        virtual void trainingSessionDidBegin(TrainingSession *session) {};
        
        // A fatal error occurred cuasing the training session to fail entirely.
        virtual void trainingSessionDidFailWithError(TrainingSession *session, Error error) {};
        
        // The training session is going to begin learning the command.
        virtual void trainingSessionDidLearnCommand(TrainingSession *session, Command command) {};
        
        // Inclusive arbitrary input indicates all buttons should be pressed – in no specific order (i.e., arbitrary).
        virtual void trainingSessionDidRequestInclusiveArbitraryInput(TrainingSession *session) {};
        
        // Input should be provided for a single command, that is the one that is passed as a parameter.
        virtual void trainingSessionDidRequestInputForCommand(TrainingSession *session, Command command) {};
        
        // Exclusive arbitrary input indicates that a single arbitrary command (i.e., button) should be pressed.
        virtual void trainingSessionDidRequestExclusiveArbitraryInput(TrainingSession *session) {};
    };
}

#endif /* TrainingSession_hpp */
