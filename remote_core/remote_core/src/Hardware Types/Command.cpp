//
//  Command.cpp
//  remote_core
//
//  Created by David Moore on 11/7/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include "Command.hpp"

using namespace RemoteCore;

void Command::encodeWithCoder(Coder *aCoder) const {
    aCoder->encodeStringForKey(localizedTitle, "localizedTitle");
    aCoder->encodeStringForKey(commandID, "commandID");
}

void Command::decodeWithCoder(const Coder *aCoder) {
    localizedTitle = aCoder->decodeStringForKey("localizedTitle");
    commandID = aCoder->decodeStringForKey("commandID");
}
