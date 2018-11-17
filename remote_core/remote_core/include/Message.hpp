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
    enum class MessageType {
        Default     = 0,
        Training    = 1,
        Command     = 2
    };
    
    class Message : public Coding {
    private:
        std::string messageID;
        MessageType type;
        
    public:
        Message(MessageType type = MessageType::Default);
        
        // MARK: - Properties
        
        /**
         Unique identifier for a particular message.
         */
        std::string getMessageID() {
            return messageID;
        }
        
        /**
         Type of the message that is represented. Default value is 'MessageType::Default'.
         */
        MessageType getMessageType(void) {
            return type;
        }
        
        // MARK: - Coding
        
        void encodeWithCoder(Coder *aCoder) const override;
        void decodeWithCoder(const Coder *aCoder) override;
    };
}

#endif /* Message_hpp */
