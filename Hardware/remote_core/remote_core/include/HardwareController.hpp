//
//  HardwareController.hpp
//  remote_core
//
//  Created by David Moore on 11/5/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#ifndef HardwareController_hpp
#define HardwareController_hpp

#include "RemoteController.hpp"
#include "TrainingSession.hpp"

namespace RemoteCore {
    class HardwareController {
    private:
        std::shared_ptr<TrainingSession> currentTrainingSession;
        
    public:
        HardwareController();
        
        typedef std::function<void (void)> CompletionHandler;
        
        // MARK: - Command Sending
        
        // FIXME: Create a Command class and/or a Device class to abstract this logic.
        void sendCommandToDeviceWithCompletionHandler(std::string command, std::string device,
                                                      CompletionHandler completionHandler);
        
        // MARK: - Training
        
        /**
         Returns a new training session that can be started when appropriate.
         */
        std::shared_ptr<TrainingSession> newTrainingSession(void);
        
        /**
         Starts a training session when there is no other active training session. Attempting to start a new training session while there is a current active training session will result in an exception being thrown.
         */
        void startTrainingSession(std::shared_ptr<TrainingSession> trainingSession);
        
        /**
         Suspends the current training session. If the training session provided is not actively training then nothing will happen.
         */
        void suspendTrainingSession(std::shared_ptr<TrainingSession> trainingSession);
        
        /**
         Returns whether or not the receiver has an active training session.
         */
        bool hasActiveTrainingSession(void) {
            return currentTrainingSession != nullptr;
        }
    };
}

#endif /* HardwareController_hpp */
