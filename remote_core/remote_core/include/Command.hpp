//
//  Command.hpp
//  remote_core
//
//  Created by David Moore on 11/7/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#ifndef Command_hpp
#define Command_hpp

#include "Coding.hpp"

namespace RemoteCore {
    class Command : public Coding {
    private:
        std::string localizedTitle;
        std::string commandID;
        
    public:
        Command() {}
        Command(std::string localizedTitle, std::string commandID) : localizedTitle(localizedTitle), commandID(commandID) {};
        
        void encodeWithCoder(Coder *aCoder) const override;
        void decodeWithCoder(const Coder *aCoder) override;
        
        std::string getCommandID(void) const {
            return commandID;
        }
        
        std::string getLocalizedTitle(void) const {
            return localizedTitle;
        }
        
        bool operator==(const Command &rhs) const {
            return localizedTitle == rhs.localizedTitle && commandID == rhs.commandID;
        }
        
        bool operator !=(const Command &rhs) const {
            return !(*this == rhs);
        }
    };
}

#endif /* Command_hpp */
