//
//  File.swift
//  
//
//  Created by Emory Dunn on 9/12/21.
//

import Foundation
import OpenCombine

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension LightMQTT {
    /// Returns a publisher that wraps an MQTT client.
    func packetPublisher() -> LightMQTTPublisher {
        LightMQTTPublisher(client: self)
    }
}

class LightMQTTPublisher: Publisher {
    
    typealias Output = String
    
    typealias Failure = Never
    
    static let queue = DispatchQueue(label: "MQTTPublisher", qos: .background)
    
    let client: LightMQTT
    
    var futureTopics: [String] = []
    
    init(client: LightMQTT) {
        self.client = client
    }
    
    // MARK: Combine
    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        Swift.print("MQTTPublisher", #function)
        let subscription = MQTTSubscription(client: client, target: subscriber, futureTopics: futureTopics)
        subscriber.receive(subscription: subscription)
    }
    
}

extension LightMQTTPublisher {
    class MQTTSubscription<Target: Subscriber>: Subscription where Target.Input == Output, Target.Failure == Failure {
        
        let client: LightMQTT
        var target: Target?
        var futureTopics: [String]
        
        var demand: Subscribers.Demand = .none
        
        init(client: LightMQTT, target: Target, futureTopics: [String]) {
            self.client = client
            self.target = target
            self.futureTopics = futureTopics
            
            client.connect { success in
                guard success else {
                    target.receive(completion: .finished)
                    return
                }
                
                Swift.print("Subscribing to topics with broker:")
                futureTopics.forEach { topic in
                    Swift.print("\t- \(topic)")
                    client.subscribe(to: topic)
                }

            }
            
            client.receivingMessage = receiveMessage
        }
        
        func receiveMessage(_ topic: String, _ message: String) {
            guard let target = target else {
                Swift.print("Received a message from \(topic) with no target.")
                return
            }
            
            self.demand = target.receive(message)
        }
        
        func request(_ demand: Subscribers.Demand) {
            self.demand = demand
        }
        
        func cancel() {
            target = nil
            client.disconnect()
        }
        
    }
}
//
//extension Publisher where Output == MQTTPacket, Failure == Error {
//
//    /// Filter out packets that aren't MQTT publish packets
//    func filterForSubscriptions() -> AnyPublisher<PublishPacket, Failure> {
//        self.compactMap { $0 as? PublishPacket }
//            .eraseToAnyPublisher()
//    }
//}

extension LightMQTTPublisher {
    
    /// Subscribe to a topic after the client has connected.
    /// - Parameters:
    ///   - topic: The MQTT topic to subscribe to.
    func subscribe(to topic: String) -> LightMQTTPublisher {
        // Save the topics for later
        self.futureTopics.append(topic)
        
        return self
    }
    
}
