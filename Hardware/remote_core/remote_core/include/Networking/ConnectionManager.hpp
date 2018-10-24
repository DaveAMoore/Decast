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
    protected:
        std::shared_ptr<awsiotsdk::NetworkConnection> networkConnection;
        std::shared_ptr<awsiotsdk::mqtt::ConnectPacket> connectPacket;
        std::atomic_int currentPendingMessages;
        std::atomic_int totalPublishedMessages;
        std::shared_ptr<awsiotsdk::MqttClient> client;
        std::unique_ptr<awsiotsdk::Utf8String> clientID;
        std::vector<std::string> subscribedTopicNames;
        
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
        
    public:
        /**
         Asynchronous callback that is used for handling the completion of tasks.
         */
        typedef std::function<void (awsiotsdk::ResponseCode responseCode)> CompletionHandler;
        
        
        ConnectionManager(const awsiotsdk::util::String &configFileRelativePath);
        
        /// Attempts to resume, or establish, a connection with the endpoint. (Synchronous)
        
        /**
         Attempts to resume, or initally establish, a connection with the endpoint.

         @return Response code indicating if the operation was completed successfully, or failed.
         */
        awsiotsdk::ResponseCode resumeConnection(void);
        
        /**
         Subscribes to a topic, given the name of a particular topic. (Asynchronous)

         @param topicName The name of the topic that will be subscribed to.
         @param completionHandler Called when the subscription has been completed, or has failed.
         */
        void subscribeToTopic(const std::string topicName, CompletionHandler completionHandler);
        
        /**
         Ubsubscribes from a topic, given the name of the topic to unsubscribe from. (Asynchronous)

         @param topicName Topic that will be unsubscribed from.
         @param completionHandler Called when the unsubscribing is completed, or an error occurred.
         */
        void unsubscribeFromTopic(const std::string topicName, CompletionHandler completionHandler);
        
        /**
         Publish a message to a topic, which is specified. (Asynchronous)

         @param message JSON string that will be published.
         @param topicName Name of the topic that the message will be published to.
         @param completionHandler Called when the message has been published, or an error occurred.
         */
        void publishMessageToTopic(const std::string message, const std::string topicName, CompletionHandler completionHandler);
        
        /**
         Returns a vector of topic names that are currently subscribed to.
         */
        std::vector<std::string> getSubscribedTopicNames(void) {
            return subscribedTopicNames;
        }
    };
}

#endif /* ConnectionManager_hpp */
