//
//  SensorDataMQTTPublisher.swift
//  
//
//  Created by Emory Dunn on 11/22/21.
//

import Foundation
import MQTT
import SwiftyGPIO

/// Read incoming data from a sensor and publish it to an MQTT topic.
///
/// This class is primarily meant for republishing data from a local sensor to a remote location for debugging. 
public class SensorDataMQTTPublisher {

    let sensor: AMGSensorProtocol
    
    let client: AsyncMQTTClient
    let topic: String
    
    var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }()
    
    public init(sensor: AMGSensorProtocol, client: AsyncMQTTClient, topic: String) {
        self.sensor = sensor
        self.client = client
        self.topic = topic
    }
    
    public convenience init(board: SupportedBoard, address: Int, client: AsyncMQTTClient, topic: String) {
        self.init(sensor: I2CAMGSensor(board: board, address: address),
                  client: client,
                  topic: topic)
    }
    
    public func publishData(retain: Bool, qos: QoS) async throws {
        
        for try await sensorData in sensor.data {
            // Encode the data
            let data = try encoder.encode(sensorData)
        
            client.publish(topic: topic, retain: retain, qos: qos, payload: data, identifier: nil)
        }
    }
    
}
