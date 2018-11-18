//
//  Device.hpp
//  remote_core
//
//  Created by David Moore on 11/18/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#ifndef Device_hpp
#define Device_hpp

#include "Coding.hpp"

namespace RemoteCore {
    class Device : public Coding {
    private:
        std::string serialNumber;
        
    public:
        Device(std::string serialNumber) : serialNumber(serialNumber) {};
        
        /// The current device which this code is being run on.
        static Device currentDevice(void);
        
        /// Returns the serial number of the device.
        std::string getSerialNumber(void) { return serialNumber; }
        
        void encodeWithCoder(Coder *aCoder) const override;
        void decodeWithCoder(const Coder *aCoder) override;
        
        bool operator ==(const Device &rhs) const {
            return serialNumber == rhs.serialNumber;
        }
        
        bool operator !=(const Device &rhs) const {
            return !(*this == rhs);
        }
    };
}

#endif /* Device_hpp */
