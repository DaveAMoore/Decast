//
//  HardwareController.hpp
//  remote_core
//
//  Created by David Moore on 11/5/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#ifndef HardwareController_hpp
#define HardwareController_hpp

#include <vector>
#include "TrainingSession.hpp"
#include "Remote.hpp"

namespace RemoteCore {
    class HardwareController {
    private:
        std::vector<std::string> sessionIDs;
        std::shared_ptr<TrainingSession> currentTrainingSession;
        
        /**
         Determines if a configuration file exists for remoteID.
         
         @param remoteName
         @return 1 for remote found and -1 for not found
         */
        bool doesRemoteExist(Remote &remote);
        
    public:
        HardwareController();
        
        typedef std::function<void (Error)> CompletionHandler;
        
        // MARK: - Command Sending

        /**
         Sends a command to an external device (i.e., controlled by the remote) through infrared.

         @param command The command that will be sent.
         @param remote The remote the command is associated with.
         @param completionHandler Called when the command has been sent, or an error occurred.
         */
        void sendCommandForRemoteWithCompletionHandler(Command command, Remote remote,
                                                       CompletionHandler completionHandler);
        
        // MARK: - Training
        
        /**
         Returns a new training session that can be started when appropriate.
         */
        std::shared_ptr<TrainingSession> newTrainingSessionForRemote(Remote remote);
        
        /**
         Starts a training session when there is no other active training session. Attempting to start a new training session while there is a current active training session will result in an exception being thrown.
         */
        void startTrainingSession(std::shared_ptr<TrainingSession> trainingSession);
        
        /**
         Suspends the current training session. If the training session provided is not actively training then nothing will happen.
         */
        void suspendTrainingSession(std::shared_ptr<TrainingSession> trainingSession);
        
        /**
         Invalidates the training session; preventing it from being used in the future.
         */
        void invalidateTrainingSession(std::shared_ptr<TrainingSession> trainingSession);
        
        /**
         Returns whether or not the receiver has an active training session.
         */
        bool hasActiveTrainingSession(void) {
            return currentTrainingSession != nullptr;
        }
    };
}

#endif /* HardwareController_hpp */
