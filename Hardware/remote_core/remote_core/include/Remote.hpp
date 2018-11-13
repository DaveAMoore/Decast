//
//  Remote.hpp
//  remote_core
//
//  Created by David Moore on 11/8/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#ifndef Remote_hpp
#define Remote_hpp

#include <iostream>
#include "Coding.hpp"
#include "Command.hpp"

namespace RemoteCore {
    class Remote : public Coding {
    private:
        std::string localizedTitle;
        std::string remoteID;
        std::vector<Command> commands;
        
    public:
        Remote() {}
        Remote(std::string localizedTitle, std::string remoteID) : localizedTitle(localizedTitle), remoteID(remoteID) {};
        
        void encodeWithCoder(Coder *aCoder) const override;
        void decodeWithCoder(const Coder *aCoder) override;
        
        std::string getRemoteID(void) const {
            return remoteID;
        }
        
        std::string getLocalizedTitle(void) const {
            return localizedTitle;
        }
        
        bool operator ==(const Remote &rhs) const {
            return localizedTitle == rhs.localizedTitle && remoteID == rhs.remoteID;
        }
        
        bool operator !=(const Remote &rhs) const {
            return !(*this == rhs);
        }
    };
}

#endif /* Remote_hpp */
