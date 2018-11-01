//
//  Message.hpp
//  remote_core
//
//  Created by David Moore on 10/31/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#ifndef Message_hpp
#define Message_hpp

#include "Coding.hpp"

namespace RemoteCore {
    class Message : public Coding {
    public:
        Message();
        
        void encodeWithCoder(Coder *aCoder) override;
        void decodeWithCoder(Coder *aCoder) override;
    };
}

#endif /* Message_hpp */
