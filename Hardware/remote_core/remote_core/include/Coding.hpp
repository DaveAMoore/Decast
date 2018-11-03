//
//  Coding.hpp
//  remote_core
//
//  Created by David Moore on 11/1/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#ifndef SecureCoding_hpp
#define SecureCoding_hpp

#include "Coder.hpp"

namespace RemoteCore {
    class Coding {
    public:
        virtual ~Coding() {}
        
        /**
         Encodes the receiver using a given archiver.

         @param aCoder Archiver that should be used for encoding values of the receiver.
         */
        virtual void encodeWithCoder(Coder *aCoder) = 0;
        
        /**
         Decodes the receiver using a given unarchiver.
         
         @param aCoder Unarchiver that should be used for decoding values of the receiver.
         */
        virtual void decodeWithCoder(Coder *aCoder) = 0;
    };
}

#endif /* SecureCoding_hpp */
