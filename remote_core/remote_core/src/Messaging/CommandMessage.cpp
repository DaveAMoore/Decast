//
//  CommandMessage.cpp
//  remote_core
//
//  Created by David Moore on 11/13/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include "CommandMessage.hpp"

using namespace RemoteCore;

// MARK: - Coding

void CommandMessage::encodeWithCoder(Coder *aCoder) const {
    Message::encodeWithCoder(aCoder);
}

void CommandMessage::decodeWithCoder(const Coder *aCoder) {
    Message::decodeWithCoder(aCoder);
}
