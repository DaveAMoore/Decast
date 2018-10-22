//
//  ConnectionManager.hpp
//  remote_core
//
//  Created by David Moore on 10/21/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#ifndef ConnectionManager_hpp
#define ConnectionManager_hpp

#include "mqtt/Client.hpp"
#include "NetworkConnection.hpp"

namespace remote_core {
    /// Manages connections with the IoT Core.
    class ConnectionManager {
    private:
        std::string topicName;
        
    protected:
        std::shared_ptr<awsiotsdk::NetworkConnection> networkConnection;
        std::shared_ptr<awsiotsdk::mqtt::ConnectPacket> connectPacket;
        std::atomic_int currentPendingMessages;
        std::atomic_int totalPublishedMessages;
        std::shared_ptr<awsiotsdk::MqttClient> client;
        std::unique_ptr<awsiotsdk::Utf8String> clientID;
        
        awsiotsdk::ResponseCode subscribeCallback(awsiotsdk::util::String topicName,
                                                  awsiotsdk::util::String payload,
                                                  std::shared_ptr<awsiotsdk::mqtt::SubscriptionHandlerContextData> handlerData);
        awsiotsdk::ResponseCode disconnectCallback(awsiotsdk::util::String topicName,
                                                   std::shared_ptr<awsiotsdk::DisconnectCallbackContextData> handlerData);
        awsiotsdk::ResponseCode reconnectCallback(awsiotsdk::util::String clientID,
                                                  std::shared_ptr<awsiotsdk::ReconnectCallbackContextData> handlerData,
                                                  awsiotsdk::ResponseCode reconnectResult);
        awsiotsdk::ResponseCode resubscribeCallback(awsiotsdk::util::String clientID,
                                                    std::shared_ptr<awsiotsdk::ResubscribeCallbackContextData> handlerData,
                                                    awsiotsdk::ResponseCode resubscribeResult);
        
        template <typename Callback>
        void subscribe(Callback completionHandler);
        
        template <typename Callback>
        void unsubscribe(Callback completionHandler);
        
    public:
        ConnectionManager(const std::string topicName, const awsiotsdk::util::String &configFileRelativePath);
        
        /// Attempts to resume, or establish, a connection with the endpoint.
        awsiotsdk::ResponseCode resumeConnection(void);
        
        /// Returns the topic name.
        std::string getTopicName() { return topicName; }
    };
}

#endif /* ConnectionManager_hpp */
