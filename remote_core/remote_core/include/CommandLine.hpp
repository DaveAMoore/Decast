//
//  CommandLine.hpp
//  remote_core
//
//  Created by David Moore on 11/20/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#ifndef CommandLine_hpp
#define CommandLine_hpp

#include <memory>
#include <functional>
#include "DispatchQueue.hpp"

namespace RemoteCore {
    /**
     Abstraction for running commands on the command line.
     */
    class CommandLine {
    private:
        std::unique_ptr<DispatchQueue> queue;
        
    public:
        CommandLine();
        
        /**
         Returns the shared command line object, initialized lazily.
         */
        static std::shared_ptr<CommandLine> sharedCommandLine();
        
        /**
         Executes a command within the current directory in the system.

         @param command Command that will be executed.
         @param std::string Current result of the command execution.
         @param bool Indicates if the command has been fully executed and is complete.
         */
        void executeCommandWithResultHandler(const char *command, std::function<void (std::string, bool)> resultHandler);
    };
}

#endif /* CommandLine_hpp */
