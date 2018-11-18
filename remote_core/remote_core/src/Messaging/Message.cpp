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

Message::Message(MessageType type) : type(type) {
    messageID = UUID::GenerateUUIDString();
}

void Message::encodeWithCoder(Coder *aCoder) const {
    aCoder->encodeStringForKey(messageID, "messageID");
    aCoder->encodeIntForKey(std::underlying_type<MessageType>::type(type), "type");
    aCoder->encodeObjectForKey(remote.get(), "remote");
    aCoder->encodeObjectForKey(command.get(), "command");
    if (error != Error::None) {
        aCoder->encodeIntForKey(std::underlying_type<Error>::type(error), "error");
    }
}

void Message::decodeWithCoder(const Coder *aCoder) {
    messageID = aCoder->decodeStringForKey("messageID");
    type = static_cast<MessageType>(aCoder->decodeIntForKey("type"));
    remote = aCoder->decodeObjectForKey<Remote>("remote");
    command = aCoder->decodeObjectForKey<Command>("command");
    error = static_cast<Error>(aCoder->decodeIntForKey("error"));
}
