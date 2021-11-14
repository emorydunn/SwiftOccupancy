//
//  File.swift
//  
//
//  Created by Emory Dunn on 11/13/21.
//

import Foundation
import OpenCombine
import MQTTKit

extension MQTTSession {
    
    /// Returns a publisher that wraps an MQTT client.
    func messagesPublisher() -> MQTTPublisher {
        MQTTPublisher(client: self)
    }
}

/// A publisher that delivers the messages from an MQTT client.
///
/// In order to subscribe to topics call `.subscribe(_:_:)` on the publisher _before_
/// doing anything else with the publisher. The subscription requests are cached until the connection
/// with the server is made.
///
/// At any point in your pipeline you can call `.filterForSubscriptions()`, which will filter for
/// Publish messages from the server, dropping all other packets.
public class MQTTPublisher: Publisher {
    
    public typealias Output = MQTTMessage
    
    public typealias Failure = Error
    
    static let queue = DispatchQueue(label: "MQTTPublisher", qos: .background)
    
    let client: MQTTSession
    
//    var futureTopics: [String: QoS] = [:]
    
    public init(client: MQTTSession) {
        self.client = client
    }
    
    // MARK: Combine
    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        Swift.print("MQTTPublisher", #function)
        let subscription = MQTTSubscription(client: client, target: subscriber)
        subscriber.receive(subscription: subscription)
    }
}

extension MQTTPublisher {
    class MQTTSubscription<Target: Subscriber>: Subscription where Target.Input == Output, Target.Failure == Failure {
        
        let client: MQTTSession
        
        var target: Target?
        var demand: Subscribers.Demand = .none
        
        init(client: MQTTSession, target: Target) {
            self.client = client
            self.target = target
            
            client.didRecieveMessage = { message in
                self.demand = target.receive(message)
            }
        }
        
        func request(_ demand: Subscribers.Demand) {
            self.demand = demand
        }
        
        func cancel() {
            target = nil
        }
        
        
    }
}

extension MQTTPublisher {
    
    /// Subscribe to a topic after the client has connected.
    /// - Parameters:
    ///   - topic: The MQTT topic to subscribe to.
    func subscribe(to topic: String) -> AnyPublisher<MQTTMessage, Failure> {
        self.client.subscribe(to: topic)
        
        return self.filter { message in
            message.topic == topic
        }
        .eraseToAnyPublisher()
    }
}

