//
//  MQTTSensor.swift
//  
//
//  Created by Emory Dunn on 11/22/21.
//

import Foundation
import MQTT


/// A sensor that reads its data from an MQTT topic
public struct MQTTAMGSensor: AMGSensorProtocol {

    let client: AsyncMQTTClient
    let topic: String
    let decoder = JSONDecoder()

    public init(client: AsyncMQTTClient, topic: String) {
        self.client = client
        self.topic = topic
        
        client.subscribe(topic: topic, qos: .atMostOnce)
    }

    public var data: AsyncThrowingStream<SensorPayload, Error> {
        
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let pubs = client.packets.compactMap { $0 as? PublishPacket }
                    
                    for try await packet in pubs {
                        let data = try decoder.decode(SensorPayload.self, from: packet.payload)
                        
                        continuation.yield(data)
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            
        }

    }

}
