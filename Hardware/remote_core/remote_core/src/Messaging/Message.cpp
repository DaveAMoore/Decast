//
//  Message.cpp
//  remote_core
//
//  Created by David Moore on 10/31/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include "Message.hpp"

using namespace RemoteCore;

Message::Message() {
    
}

void Message::encodeWithCoder(Coder *aCoder) {
    
}

void Message::decodeWithCoder(Coder *aCoder) {
    auto demo = aCoder->decodeObjectForKey<Message>("Hello");
}
