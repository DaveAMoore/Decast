//
//  Remote.cpp
//  remote_core
//
//  Created by David Moore on 11/8/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include "Remote.hpp"

using namespace RemoteCore;

void Remote::encodeWithCoder(Coder *aCoder) const {
    aCoder->encodeStringForKey(localizedTitle, "localizedTitle");
    aCoder->encodeStringForKey(remoteID, "remoteID");
}

void Remote::decodeWithCoder(const Coder *aCoder) {
    localizedTitle = aCoder->decodeStringForKey("localizedTitle");
    remoteID = aCoder->decodeStringForKey("remoteID");
}

