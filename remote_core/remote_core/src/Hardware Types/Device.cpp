//
//  Device.cpp
//  remote_core
//
//  Created by David Moore on 11/18/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include "Device.hpp"
#include "ConfigCommon.hpp"

using namespace RemoteCore;

Device Device::currentDevice() {
    return Device(awsiotsdk::ConfigCommon::serial_number_);
}

void Device::encodeWithCoder(Coder *aCoder) const {
    aCoder->encodeStringForKey(serialNumber, "serialNumber");
}

void Device::decodeWithCoder(const Coder *aCoder) {
    serialNumber = aCoder->decodeStringForKey("serialNumber");
}
