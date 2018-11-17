//
//  CommandMessage.hpp
//  remote_core
//
//  Created by David Moore on 11/13/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#ifndef CommandMessage_hpp
#define CommandMessage_hpp

#include "Message.hpp"

namespace RemoteCore {
    class CommandMessage final : public Message {
    private:
        
        
    public:
        
        // MARK: - Coding
        
        void encodeWithCoder(Coder *aCoder) const override;
        void decodeWithCoder(const Coder *aCoder) override;
    };
}

#endif /* CommandMessage_hpp */
