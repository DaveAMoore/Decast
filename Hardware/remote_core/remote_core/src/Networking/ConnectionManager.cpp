//
//  ConnectionManager.cpp
//  remote_core
//
//  Created by David Moore on 10/21/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include <chrono>
#include <cstring>
#include <algorithm>
#include "ConnectionManager.hpp"
#include "OpenSSLConnection.hpp"
#include "ConfigCommon.hpp"
#include "util/logging/Logging.hpp"
#include "util/logging/LogMacros.hpp"
#include "util/logging/ConsoleLogSystem.hpp"

using namespace RemoteCore;
using namespace awsiotsdk;

// MARK: - Connection Manager Implementation

ConnectionManager::ConnectionManager(const std::string &configFileRelativePath,
                                     const awsiotsdk::mqtt::QoS qualityOfService) : currentPendingMessages(0), totalPublishedMessages(0), qualityOfService(qualityOfService) {
    // Initialize the common configuration then create an SSL connection.
    ConfigCommon::InitializeCommon(configFileRelativePath);
    auto tlsConnection = std::make_shared<network::OpenSSLConnection>(ConfigCommon::endpoint_,
                                                                      ConfigCommon::endpoint_mqtt_port_,
                                                                      ConfigCommon::root_ca_path_,
                                                                      ConfigCommon::client_cert_path_,
                                                                      ConfigCommon::client_key_path_,
                                                                      ConfigCommon::tls_handshake_timeout_,
                                                                      ConfigCommon::tls_read_timeout_,
                                                                      ConfigCommon::tls_write_timeout_,
                                                                      true);
    
    // Initialize the TLS connection.
    ResponseCode responseCode = tlsConnection->Initialize();
    if (responseCode != ResponseCode::SUCCESS) {
        assert(false && "An error occurred while initializing the TLS connection.");
    } else {
        networkConnection = std::dynamic_pointer_cast<NetworkConnection>(tlsConnection);
    }
    
    // Get references for the callbacks.
    ClientCoreState::ApplicationDisconnectCallbackPtr disconnectCallback =
    std::bind(&ConnectionManager::disconnectCallback,
              this,
              std::placeholders::_1,
              std::placeholders::_2);
    ClientCoreState::ApplicationReconnectCallbackPtr reconnectCallback =
    std::bind(&ConnectionManager::reconnectCallback,
              this,
              std::placeholders::_1,
              std::placeholders::_2,
              std::placeholders::_3);
    ClientCoreState::ApplicationResubscribeCallbackPtr resubscribeCallback =
    std::bind(&ConnectionManager::resubscribeCallback,
              this, std::placeholders::_1,
              std::placeholders::_2,
              std::placeholders::_3);
    
    // Create a new connection client.
    client = std::shared_ptr<MqttClient>(MqttClient::Create(networkConnection,
                                                            ConfigCommon::mqtt_command_timeout_,
                                                            disconnectCallback, nullptr,
                                                            reconnectCallback, nullptr,
                                                            resubscribeCallback, nullptr));
    
    if (client == nullptr) {
        assert(false && "An error occurred while initializing the MQTT client.");
    }
    
    // Configure the client.
    client->SetAutoReconnectEnabled(true);
    
    // Process the client ID.
    auto clientIDTagged = ConfigCommon::base_client_id_;
    //clientIDTagged.append("");
    clientID = Utf8String::Create(clientIDTagged);
}

ResponseCode ConnectionManager::resumeConnection() {
    // Prevent connecting multiple times.
    if (client->IsConnected()) {
        return ResponseCode::SUCCESS;
    }
    
    // Establish an MQTT connection.
    ResponseCode responseCode = client->Connect(ConfigCommon::mqtt_command_timeout_,
                                                ConfigCommon::is_clean_session_,
                                                mqtt::Version::MQTT_3_1_1,
                                                ConfigCommon::keep_alive_timeout_secs_,
                                                std::move(clientID),
                                                nullptr, nullptr, nullptr);
    
    return responseCode;
}

ResponseCode ConnectionManager::suspendConnection(void) {
    // Prevent disconnecting if already disconnected.
    if (!client->IsConnected()) {
        return ResponseCode::SUCCESS;
    }
    
    // Disconnect from the MQTT connection.
    return client->Disconnect(ConfigCommon::mqtt_command_timeout_);
}

void ConnectionManager::subscribeToTopic(const std::string &topicName, MessageHandler messageHandler,
                                         CompletionHandler completionHandler) {
    auto topicNamePtr = Utf8String::Create(topicName);
    mqtt::Subscription::ApplicationCallbackHandlerPtr subscriptionHandler =
    std::bind(&ConnectionManager::subscribeCallback,
              this, std::placeholders::_1,
              std::placeholders::_2,
              std::placeholders::_3);
    
    auto subscription = mqtt::Subscription::Create(std::move(topicNamePtr), qualityOfService, subscriptionHandler, nullptr);
    util::Vector<std::shared_ptr<mqtt::Subscription>> subscriptionVector;
    subscriptionVector.push_back(subscription);
    
    uint16_t packet_id_out;
    client->SubscribeAsync(subscriptionVector, [&, messageHandler, completionHandler, topicName](uint16_t actionID, ResponseCode responseCode) {
        if (responseCode == ResponseCode::SUCCESS) {
            {
                std::lock_guard<std::mutex> lock(subscribedTopicNamesMutex);
                subscribedTopicNames.push_back(topicName);
            }
            
            if (messageHandler) {
                std::lock_guard<std::mutex> lock(messageHandlersByTopicNameMutex);
                messageHandlersByTopicName.emplace(std::make_pair(topicName, messageHandler));
            }
        }
        
        if (completionHandler) {
            completionHandler(responseCode);
        }
    }, packet_id_out);
}

void ConnectionManager::unsubscribeFromTopic(const std::string &topicName,
                                             CompletionHandler completionHandler) {
    auto topicNamePtr = Utf8String::Create(topicName);
    util::Vector<std::unique_ptr<Utf8String>> topicVector;
    topicVector.push_back(std::move(topicNamePtr));
    
    uint16_t packetIDOut;
    client->UnsubscribeAsync(std::move(topicVector), [&, completionHandler, topicName](uint16_t actionID, ResponseCode responseCode) {
        if (responseCode == ResponseCode::SUCCESS) {
            {
                std::lock_guard<std::mutex> lock(subscribedTopicNamesMutex);
                auto position = std::find(subscribedTopicNames.begin(), subscribedTopicNames.end(), topicName);
                
                if (position != subscribedTopicNames.end()) {
                    auto index = subscribedTopicNames.begin() + std::distance(subscribedTopicNames.begin(),
                                                                              position);
                    subscribedTopicNames.erase(index);
                }
            }
            
            // Attempt to erase the message handler associated with the topic.
            std::lock_guard<std::mutex> lock(messageHandlersByTopicNameMutex);
            messageHandlersByTopicName.erase(topicName);
        }
        
        if (completionHandler) {
            completionHandler(responseCode);
        }
    }, packetIDOut);
}

void ConnectionManager::publishMessageToTopic(const std::string &message, const std::string &topicName,
                                              CompletionHandler completionHandler) {
    auto topicNamePtr = Utf8String::Create(topicName);
    
    uint16_t packetIDOut;
    client->PublishAsync(std::move(topicNamePtr), false, false, qualityOfService, message, [&, completionHandler](uint16_t actionID, ResponseCode responseCode) {
        if (completionHandler) {
            completionHandler(responseCode);
        }
    }, packetIDOut);
}

// TODO: Implement subscribedTopicNames management for these callbacks.
ResponseCode ConnectionManager::subscribeCallback(util::String topicName, util::String payload,
                                                  std::shared_ptr<mqtt::SubscriptionHandlerContextData> handlerData) {
    // Call the message handler, if applicable.
    std::lock_guard<std::mutex> lock(messageHandlersByTopicNameMutex);
    auto messageHandlerIt = messageHandlersByTopicName.find(topicName);
    if (messageHandlerIt != messageHandlersByTopicName.end()) {
        messageHandlerIt->second(topicName, payload);
    }
    
    return ResponseCode::SUCCESS;
}

ResponseCode ConnectionManager::disconnectCallback(util::String topicName,
                                                   std::shared_ptr<DisconnectCallbackContextData> handlerData) {
    return ResponseCode::SUCCESS;
}

ResponseCode ConnectionManager::reconnectCallback(util::String clientID,
                                                  std::shared_ptr<ReconnectCallbackContextData> handlerData,
                                                  ResponseCode reconnectResult) {
    return ResponseCode::SUCCESS;
}

ResponseCode ConnectionManager::resubscribeCallback(util::String clientID,
                                                    std::shared_ptr<ResubscribeCallbackContextData> handlerData,
                                                    ResponseCode resubscribeResult) {
    return ResponseCode::SUCCESS;
}




