//
//  RFContainerNotification.swift
//  RFCore
//
//  Created by David Moore on 8/1/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation

/// The abstract base class for CloudKit notifications.
open class RFContainerNotification: RFNotification {
    
    // MARK: - Properties
    
    /// Message representing the data provided by the receiver.
    open var message: Message
    
    // MARK: - Initialization
    
    /// Creates and returns a new notification object using the specified payload data.
    public init(fromRemoteNotificationDictionary remoteNotificationDictionary: [AnyHashable: Any]) throws {
        // Retrieve the APS payload from the notific ation.
        let apsPayload = remoteNotificationDictionary["aps"] as? [String: Any]
        
        // Retrieve the alert from the payload.
        guard let alert = apsPayload?["alert"] as? String, let data = alert.data(using: .utf8) else {
            throw CocoaError.error(.coderValueNotFound, userInfo: nil, url: nil)
        }
        
        // Attempt to decode the message.
        let decoder = JSONDecoder()
        let remoteMessage = try decoder.decode(Message.self, from: data)
        
        // Set the message.
        message = remoteMessage
    }
}

// MARK: - Types
extension RFContainerNotification {
    public struct Message: Codable, Equatable, Hashable {
        public let records: [Event]
        
        public enum CodingKeys: String, CodingKey {
            case records = "Records"
        }
    }
    
    public struct Event: Codable, Equatable, Hashable {
        public enum EventType: String {
            case objectCreated
            case objectRemoved
            
            public init?(rawValue: String) {
                if rawValue.hasPrefix("ObjectCreated") {
                    self = .objectCreated
                } else if rawValue.hasPrefix("ObjectRemoved") {
                    self = .objectRemoved
                } else {
                    return nil
                }
            }
        }
        
        public let eventTime: Date
        public let eventName: String
        public let responseElements: ResponseElements
        public let container: Container
        
        public var eventType: EventType {
            return EventType(rawValue: eventName)!
        }
        
        public enum CodingKeys: String, CodingKey {
            case eventTime
            case eventName
            case responseElements
            case container = "s3"
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            let eventTimeString = try container.decode(String.self, forKey: .eventTime)
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions.formUnion(.withFractionalSeconds)
            
            if let eventTime = dateFormatter.date(from: eventTimeString) {
                self.eventTime = eventTime
            } else {
                throw DecodingError.dataCorruptedError(forKey: .eventTime, in: container,
                                                       debugDescription: "could not parse ISO8601 date")
            }
            
            responseElements = try container.decode(ResponseElements.self, forKey: .responseElements)
            eventName = try container.decode(String.self, forKey: .eventName)
            self.container = try container.decode(Container.self, forKey: .container)
        }
    }
    
    public struct ResponseElements: Codable, Equatable, Hashable {
        
        public let requestID: String
        
        public enum CodingKeys: String, CodingKey {
            case requestID = "x-amz-request-id"
        }
    }
    
    public struct Container: Codable, Equatable, Hashable {
        public let bucket: Bucket
        public let object: Object
    }
    
    public struct Bucket: Codable, Equatable, Hashable {
        public let name: String
        public let arn: String
    }
    
    public struct Object: Codable, Equatable, Hashable {
        public let key: String
        public let size: Int?
        public let eTag: String?
        public let versionId: String?
        public let sequencer: Int?
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            let encodedKey = try container.decode(String.self, forKey: .key)
            if let decodedKey = encodedKey.replacingOccurrences(of: "+", with: " ").removingPercentEncoding {
                key = decodedKey
            } else {
                throw DecodingError.dataCorruptedError(forKey: .key, in: container, debugDescription: "'key' could not be decoded")
            }
            
            size = try? container.decode(Int.self, forKey: .size)
            eTag = try? container.decode(String.self, forKey: .eTag)
            versionId = try? container.decode(String.self, forKey: .versionId)
            if let encodedSequencer = try? container.decode(String.self, forKey: .sequencer) {
                sequencer = Int(encodedSequencer, radix: 16)
            } else {
                sequencer = nil
            }
        }
    }
}
