//
//  File.swift
//  
//
//  Created by Emory Dunn on 11/19/21.
//

import Foundation
import OpenCombine
import MQTT

extension MQTTClient {
    
    /// Returns a publisher that wraps an MQTT client.
    func messagesPublisher(_ onConnection: @escaping () -> Void) -> MQTTPublisher {
        MQTTPublisher(client: self, onConnection)
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
    
    public typealias Output = PublishPacket
    
    public typealias Failure = Error
    
    static let queue = DispatchQueue(label: "MQTTPublisher", qos: .background)
    
    let client: MQTTClient
    let onConnection: () -> Void
    
//    var futureTopics: [String: QoS] = [:]
    
    public init(client: MQTTClient, _ onConnection: @escaping () -> Void) {
        self.client = client
        self.onConnection = onConnection
    }
    
    // MARK: Combine
    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        Swift.print("MQTTPublisher", #function)
        let subscription = MQTTSubscription(client: client, target: subscriber, onConnection)
        subscriber.receive(subscription: subscription)
    }
}

extension MQTTPublisher {
    class MQTTSubscription<Target: Subscriber>: MQTTClientDelegate, Subscription where Target.Input == Output, Target.Failure == Failure {
        
        let client: MQTTClient
        let onConnection: () -> Void
        
        var target: Target?
        var demand: Subscribers.Demand = .none
        
        init(client: MQTTClient, target: Target, _ onConnection: @escaping () -> Void) {
            self.client = client
            self.target = target
            self.onConnection = onConnection
            
            self.client.delegate = self
        }
        
        func request(_ demand: Subscribers.Demand) {
            self.demand = demand
        }
        
        func cancel() {
            target = nil
            client.disconnect()
        }
        
        func mqttClient(_ client: MQTTClient, didChange state: ConnectionState) {
            Swift.print("MQTT Connection State Changed:", state)
        }
        
        func mqttClient(_ client: MQTTClient, didReceive packet: MQTTPacket) {
            switch packet {
            case let packet as ConnAckPacket:
                Swift.print("ConnAck \(packet)")
                onConnection()
            case let packet as PublishPacket:
                if let target = self.target {
                    demand = target.receive(packet)
                }
            default:
                break
            }
            

        }
        
        func mqttClient(_ client: MQTTClient, didCatchError error: Error) {
            Swift.print("Error", error)
            target?.receive(completion: .failure(error))
        }
        
        
    }
    
}

extension AnyPublisher where Output == PublishPacket, Failure == Error {
    
//    /// Subscribe to a topic after the client has connected.
//    /// - Parameters:
//    ///   - topic: The MQTT topic to subscribe to.
//    func subscribe(to topic: String, qos: QoS = .atMostOnce) -> AnyPublisher<PublishPacket, Failure> {
////        self.client.subscribe(to: topic)
//        client.subscribe(topic: topic, qos: qos, identifier: nil)
//
//        return self.filter { message in
//            message.topic == topic
//        }
//        .eraseToAnyPublisher()
//    }
    
    /// Subscribe to a topic after the client has connected.
    /// - Parameters:
    ///   - topic: The MQTT topic to subscribe to.
    func filter(to topic: String, qos: QoS = .atMostOnce) -> AnyPublisher<PublishPacket, Failure> {
        return self.filter { message in
            message.topic == topic
        }
        .eraseToAnyPublisher()
    }
}


