//
//  Message.cpp
//  remote_core
//
//  Created by David Moore on 10/31/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include "Message.hpp"
#include "UUID.hpp"

using namespace RemoteCore;

Message::Message() {
    // Generate the message ID.
    messageID = UUID::GenerateUUIDString();
}

void Message::encodeWithCoder(Coder *aCoder) const {
    aCoder->encodeStringForKey(messageID, "messageID");
}

void Message::decodeWithCoder(const Coder *aCoder) {
    messageID = aCoder->decodeStringForKey("messageID");
}
