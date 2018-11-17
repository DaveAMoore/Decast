//
//  TrainingMessage.cpp
//  remote_core
//
//  Created by David Moore on 11/13/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include "TrainingMessage.hpp"

using namespace RemoteCore;

// MARK: - Coding

void TrainingMessage::encodeWithCoder(Coder *aCoder) const {
    Message::encodeWithCoder(aCoder);
}

void TrainingMessage::decodeWithCoder(const Coder *aCoder) {
    Message::decodeWithCoder(aCoder);
}
