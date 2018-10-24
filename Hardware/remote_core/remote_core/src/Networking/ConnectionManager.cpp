//
//  ConnectionManager.cpp
//  remote_core
//
//  Created by David Moore on 10/21/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include <chrono>
#include <cstring>
#include "ConnectionManager.hpp"
#include "OpenSSLConnection.hpp"
#include "ConfigCommon.hpp"
#include "util/logging/Logging.hpp"
#include "util/logging/LogMacros.hpp"
#include "util/logging/ConsoleLogSystem.hpp"

using namespace remote_core;
using namespace awsiotsdk;

ConnectionManager::ConnectionManager(const util::String &configFileRelativePath) : totalPublishedMessages(0), currentPendingMessages(0) {
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

void ConnectionManager::subscribeToTopic(const std::string topicName, CompletionHandler completionHandler) {
    auto topicNamePtr = Utf8String::Create(topicName);
    mqtt::Subscription::ApplicationCallbackHandlerPtr subscriptionHandler =
    std::bind(&ConnectionManager::subscribeCallback,
              this, std::placeholders::_1,
              std::placeholders::_2,
              std::placeholders::_3);
    
    auto subscription = mqtt::Subscription::Create(std::move(topicNamePtr), mqtt::QoS::QOS0, subscriptionHandler, nullptr);
    util::Vector<std::shared_ptr<mqtt::Subscription>> subscriptionVector;
    subscriptionVector.push_back(subscription);
    
    uint16_t packet_id_out;
    client->SubscribeAsync(subscriptionVector, [&](uint16_t actionID, ResponseCode responseCode) {
        if (responseCode == ResponseCode::SUCCESS) {
            subscribedTopicNames.push_back(topicName);
        }
        
        completionHandler(responseCode);
    }, packet_id_out);
}

void ConnectionManager::unsubscribeFromTopic(const std::string topicName, CompletionHandler completionHandler) {
    auto topicNamePtr = Utf8String::Create(topicName);
    util::Vector<std::unique_ptr<Utf8String>> topicVector;
    topicVector.push_back(std::move(topicNamePtr));
    
    uint16_t packetIDOut;
    client->UnsubscribeAsync(topicVector, [&](uint16_t actionID, ResponseCode responseCode) {
        if (responseCode == ResponseCode::SUCCESS) {
            auto position = std::find(subscribedTopicNames.begin(), subscribedTopicNames.end(), topicName);
            
            if (position != subscribedTopicNames.end()) {
                auto index = subscribedTopicNames.begin() + std::distance(subscribedTopicNames.begin(), position);
                subscribedTopicNames.erase(index);
            }
        }
        
        completionHandler(responseCode);
    }, packetIDOut);
}

void ConnectionManager::publishMessageToTopic(std::string message, const std::string topicName, CompletionHandler completionHandler) {
    auto topicNamePtr = Utf8String::Create(topicName);
    
    uint16_t packetIDOut;
    client->PublishAsync(std::move(topicNamePtr), false, false, mqtt::QoS::QOS0, message, [&](uint16_t actionID, ResponseCode responseCode) {
        completionHandler(responseCode);
    }, packetIDOut);
}

// TODO: Implement subscribedTopicNames management these callbacks.
ResponseCode ConnectionManager::subscribeCallback(util::String topicName, util::String payload,
                                                  std::shared_ptr<mqtt::SubscriptionHandlerContextData> handlerData) {
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



