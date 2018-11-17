//
//  TrainingMessage.hpp
//  remote_core
//
//  Created by David Moore on 11/13/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#ifndef TrainingMessage_hpp
#define TrainingMessage_hpp

#include "Message.hpp"

namespace RemoteCore {
    class TrainingMessage final : public Message {
    private:
        
        
    public:
        
        // MARK: - Coding
        
        void encodeWithCoder(Coder *aCoder) const override;
        void decodeWithCoder(const Coder *aCoder) override;
    };
}

#endif /* TrainingMessage_hpp */
