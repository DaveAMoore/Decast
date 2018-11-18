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
#include "Remote.hpp"
#include "Error.hpp"

namespace RemoteCore {
    enum class MessageType {
        Default             = 0,
        Training            = 1,
        Command             = 2,
        CommandResponse     = 3,
        TrainingResponse    = 4,
    };
    
    class Message : public Coding {
    private:
        std::string senderID;
        std::string messageID;
        MessageType type;
        
    public:
        /// Remote the message is associated with.
        std::unique_ptr<Remote> remote;
        
        /// Command the message is associated with.
        std::unique_ptr<Command> command;
        
        /// Error that occurred. This should only be present with a response.
        Error error = Error::None;
        
        /// A loosely typed way to indicate what the intention of the message is.
        std::string directive;
        
        /// Initializes a new message.
        Message(MessageType type = MessageType::Default);
        
        // MARK: - Properties
        
        /**
         Unique identifier for this particular sender. On remote devices this is the serial number.
         */
        std::string getSenderID() {
            return senderID;
        }
        
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
