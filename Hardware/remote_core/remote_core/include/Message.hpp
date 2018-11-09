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
    private:
        std::string messageID;
        
    public:
        Message();
        
        /**
         Unique identifier for a particular message.
         */
        std::string getMessageID() {
            return messageID;
        }
        
        void encodeWithCoder(Coder *aCoder) const override;
        void decodeWithCoder(const Coder *aCoder) override;
    };
}

#endif /* Message_hpp */
