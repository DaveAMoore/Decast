//
//  Message.cpp
//  remote_core
//
//  Created by David Moore on 10/31/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include "Message.hpp"
#include <uuid/uuid.h>

using namespace RemoteCore;

Message::Message() {
    // Generate the message ID.
    uuid_t encodedUUID;
    uuid_generate(encodedUUID);
    
    char uuidString[64];
    uuid_unparse(encodedUUID, uuidString);
    
    messageID = std::string(uuidString);
}

void Message::encodeWithCoder(Coder *aCoder) const {
    aCoder->encodeStringForKey(messageID, "messageID");
}

void Message::decodeWithCoder(const Coder *aCoder) {
    messageID = aCoder->decodeStringForKey("messageID");
}
