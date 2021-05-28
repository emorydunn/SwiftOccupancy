//
//  MQTT.swift
//  
//
//  Created by Emory Dunn on 5/24/21.
//

import Foundation
import MQTT
import OpenCombineShim


extension MQTTClient {
    
    /// Returns a publisher that wraps an MQTT client.
    func packetPublisher() -> MQTTPublisher {
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
    
    public typealias Output = MQTTPacket
    
    public typealias Failure = Error
    
    static let queue = DispatchQueue(label: "MQTTPublisher", qos: .background)
    
    let client: MQTTClient
    
    var futureTopics: [String: QoS] = [:]
    
    public init(client: MQTTClient) {
        self.client = client
    }
    
    // MARK: Combine
    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        Swift.print("MQTTPublisher", #function)
        let subscrption = Subscription(client: client, target: subscriber, futureTopics: futureTopics)
        subscriber.receive(subscription: subscrption)
    }
}

extension MQTTPublisher {
    class Subscription<Target: Subscriber>: MQTTClientDelegate, Combine.Subscription where Target.Input == Output, Target.Failure == Failure {
        
        let client: MQTTClient
        var target: Target?
        var futureTopics: [String: QoS]
        
        //        var delegateDispatchQueue: DispatchQueue {
        //            MQTTPublisher.queue
        //        }
        
        var demand: Subscribers.Demand = .none
        
        init(client: MQTTClient, target: Target, futureTopics: [String: QoS]) {
            self.client = client
            self.target = target
            self.futureTopics = futureTopics
            client.delegate = self
            
            client.connect()
        }
        
        func request(_ demand: Subscribers.Demand) {
            self.demand = demand
            Swift.print("Got request with \(demand)")
        }
        
        func cancel() {
            target = nil
            client.disconnect()
        }
        
        // MARK: Delegate
        public func mqttClient(_ client: MQTTClient, didReceive packet: MQTTPacket) {
            
            guard let target = target else {
                Swift.print("Received packet \(packet) with no target")
                return
            }
            
            if packet is ConnAckPacket {
                Swift.print("Subscribing to topics with broker:")
                futureTopics.forEach { topic, qos in
                    Swift.print("\t- \(topic) \(qos)")
                    client.subscribe(topic: topic, qos: qos)
                }
            }
            
            self.demand = target.receive(packet)
        }
        
        public func mqttClient(_: MQTTClient, didChange state: ConnectionState) {
            //            Swift.print("MQTTPublisher", #function, state)
        }
        
        public func mqttClient(_: MQTTClient, didCatchError error: Error) {
            Swift.print("MQTT Client Error:", error)
            switch client.state {
            case .disconnected:
                client.connect()
            default:
                break
            }
            
//            target?.receive(completion: .failure(error))
        }
    }
    
    
}

extension Publisher where Output == MQTTPacket, Failure == Error {
    
    /// Filter out packets that aren't MQTT publish packets
    func filterForSubscriptions() -> AnyPublisher<PublishPacket, Failure> {
        self.compactMap { $0 as? PublishPacket }
            .eraseToAnyPublisher()
    }
}

extension MQTTPublisher {
    
    /// Subscribe to a topic after the client has connected.
    /// - Parameters:
    ///   - topic: The MQTT topic to subscribe to.
    ///   - qos: The QoS
    func subscribe(topic: String, qos: QoS) -> MQTTPublisher {
        // Save the topics for later
        self.futureTopics[topic] = qos
        
        return self
    }
    
//    func print(_ prefix: String = "", to stream: TextOutputStream? = nil) -> MQTTPublisher {
//        self.print(prefix, to: stream)
//        return self
//    }
    
    
}
