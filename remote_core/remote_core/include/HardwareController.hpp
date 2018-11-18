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
#include "RemoteController.hpp"
#include "TrainingSession.hpp"
#include "Remote.hpp"

namespace RemoteCore {
    class HardwareController {
    private:
        std::vector<std::string> sessionIDs;
        std::shared_ptr<TrainingSession> currentTrainingSession;
        
    public:
        HardwareController();
        
        typedef std::function<void (void)> CompletionHandler;
        
        // MARK: - Command Sending
        
        /**
         Sends a command through infrared to an external device.
         
         @param command The command that will be sent.
         @param deviceID
         @param completionHandler <#completionHandler description#>
         */
        void sendCommandWithCompletionHandler(Command command, CompletionHandler completionHandler);
        
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

        void sendCommand(Remote remote, Command command);
    };
}

#endif /* HardwareController_hpp */
