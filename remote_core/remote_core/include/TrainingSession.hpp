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

#define START_TRAINING_SESSION_DIRECTIVE "startTrainingSession"
#define SUSPEND_TRAINING_SESSION_DIRECTIVE "suspendTrainingSession"
#define CREATE_COMMAND_DIRECTIVE "createCommandWithLocalizedTitle"
#define LEARN_COMMAND_DIRECTIVE "learnCommand"

#define TRAINING_SESSION_DID_BEGIN_DIRECTIVE "trainingSessionDidBegin"
#define TRAINING_SESSION_DID_FAIL_WITH_ERROR_DIRECTIVE "trainingSessionDidFailWithError"
#define TRAINING_SESSION_WILL_LEARN_COMMAND_DIRECTIVE "trainingSessionWillLearnCommand"
#define TRAINING_SESSION_DID_LEARN_COMMAND_DIRECTIVE "trainingSessionDidLearnCommand"
#define TRAINING_SESSION_DID_REQUEST_INCLUSIVE_ARBITRARY_INPUT_DIRECTIVE "trainingSessionDidRequestInclusiveArbitraryInput"
#define TRAINING_SESSION_DID_REQUEST_INPUT_FOR_COMMAND_DIRECTIVE "trainingSessionDidRequestInputForCommand"
#define TRAINING_SESSION_DID_REQUEST_EXCLUSIVE_ARBITRARY_INPUT_DIRECTIVE "trainingSessionDidRequestExclusiveArbitraryInput"

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
        
        std::string getSessionID(void) const {
            return sessionID;
        }
        
        Remote getAssociatedRemote(void) const {
            return associatedRemote;
        }
        
        std::weak_ptr<TrainingSessionDelegate> getDelegate(void) {
            return delegate;
        }
        
        void setDelegate(std::weak_ptr<TrainingSessionDelegate> delegate) {
            this->delegate = delegate;
        }
        
        /**
         Initializes the training session. This will require user input (e.g., inclusive arbitrary input).
         */
        void start(void);
        
        /**
         Suspends the training session almost immediately.
         */
        void suspend(void);
        
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
    
    class TrainingSessionDelegate : public std::enable_shared_from_this<TrainingSessionDelegate> {
    public:
        // The training session is beginning.
        virtual void trainingSessionDidBegin(TrainingSession *session) {};
        
        // A fatal error occurred cuasing the training session to fail entirely.
        virtual void trainingSessionDidFailWithError(TrainingSession *session, Error error) {};
        
        // The training session is going to begin learning the command.
        virtual void trainingSessionWillLearnCommand(TrainingSession *session, Command command) {};
        virtual void trainingSessionDidLearnCommand(TrainingSession *session, Command command) {};
        
        // Inclusive arbitrary input indicates all buttons should be pressed – in no specific order (i.e., arbitrary).
        virtual void trainingSessionDidRequestInclusiveArbitraryInput(TrainingSession *session) {};
        
        // Input should be provided for a single command, that is the one that is passed as a parameter.
        virtual void trainingSessionDidRequestInputForCommand(TrainingSession *session, Command command) {};
        
        // Exclusive arbitrary input indicates that a single arbitrary command (i.e., button) should be pressed
        virtual void trainingSessionDidRequestExclusiveArbitraryInput(TrainingSession *session) {};
    };
}

#endif /* TrainingSession_hpp */
