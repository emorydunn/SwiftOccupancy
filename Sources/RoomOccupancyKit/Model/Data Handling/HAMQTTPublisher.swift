//
//  File.swift
//  
//
//  Created by Emory Dunn on 11/22/21.
//

import Foundation
import MQTT
import SwiftyGPIO

/// A class that consumes occupancy changes and publishes the state to Home Assistant.
public struct HAMQTTPublisher {

    public let sensor: AMGSensorProtocol
    
    public let client: AsyncMQTTClient
    
    public let counter: OccupancyCounter
    
    public var clientID: String { client.clientID }
    
    // MQTT Topics
    var mqttTopic: String { "homeassistant/camera/swift-occupancy/\(clientID)" }
    var statusTopic: String { "swift-occupancy/sensor/\(clientID)/status" }
    var stateTopic: String { "\(mqttTopic)/state" }
    var configTopic: String { "\(mqttTopic)/config" }
    
    public init(sensor: AMGSensorProtocol, client: AsyncMQTTClient, counter: OccupancyCounter) {
        self.sensor = sensor
        self.client = client
        self.counter = counter
    }
    
    public init(sensor: AMGSensorProtocol, client: AsyncMQTTClient, topRoom: Room = .æther, bottomRoom: Room = .æther) {
        self.sensor = sensor
        self.client = client
        self.counter = OccupancyCounter(sensor: sensor, topRoom: topRoom, bottomRoom: bottomRoom)
    }
    
    public init(board: SupportedBoard, client: AsyncMQTTClient, topRoom: Room = .æther, bottomRoom: Room = .æther) {
        self.sensor = I2CAMGSensor(board: board)
        self.client = client
        self.counter = OccupancyCounter(sensor: sensor, topRoom: topRoom, bottomRoom: bottomRoom)
    }
    
    public func setupHA() {
        
        // Publish main sensor config
        publishSensorConfig(client)
        publishCameraConfig(client)
        
        // Publish room sensor configs
        counter.topRoom.publishSensorConfig(client.client, availabilityTopic: self.statusTopic)
        counter.bottomRoom.publishSensorConfig(client.client, availabilityTopic: self.statusTopic)
        
        // Publish HA status
        client.publish(message: statusMessage(true))
        
        client.client.willMessage = statusMessage(false)
    }
    
    public func publishData() async throws {
        try await counter.publishChanges(to: client)
    }
}

extension HAMQTTPublisher {
    
    public func statusMessage(_ status: Bool) -> PublishMessage {
        PublishMessage(topic: statusTopic, payload: status ? "online" : "offline", retain: false, qos: .atMostOnce)
    }
    
    func publishSensorConfig(_ client:  AsyncMQTTClient) {
        
        let mqttTopic = "homeassistant/sensor/swift-occupancy/\(clientID)"
        
        let config: [String: Any] = [
            "name": "\(clientID) Temperature",
            "unique_id": "\(clientID)-temperature",
            "state_class": "measurement",
            "unit_of_measurement": "ºC",
            "icon": "mdi:thermometer",
            "state_topic": "\(mqttTopic)/state",
            "device": [
                "name": "\(clientID) Thermopile",
                "model": "AMG88xx",
                "identifiers": "\(clientID)-thermopile"
            ],
            "availability": [
                "topic": statusTopic
            ]
                
        ]
        
        do {
            let payload = try JSONSerialization.data(withJSONObject: config, options: [])
            
            client.publish(topic: "\(mqttTopic)/config", retain: true, qos: .atMostOnce, payload: payload, identifier: nil)

            print("Published MQTT discovery topic for \(self)")
        } catch {
            print("Could not encode MQTT discovery config for \(self)")
            print(error)
        }
    }
    
    func publishCameraConfig(_ client:  AsyncMQTTClient) {

        let config: [String: Any] = [
            "name": "\(clientID) Heatmap",
            "unique_id": "\(clientID)-thermopile",
            "topic": "\(mqttTopic)/state",
            "device": [
                "name": "\(clientID) Thermopile",
                "model": "AMG88xx",
                "identifiers": "\(clientID)-thermopile"
            ],
            "availability": [
                "topic": statusTopic
            ]
                
        ]
        
        do {
            let payload = try JSONSerialization.data(withJSONObject: config, options: [])
            
            client.publish(topic: configTopic, retain: true, qos: .atMostOnce, payload: payload, identifier: nil)

            print("Published MQTT discovery topic for \(self)")
        } catch {
            print("Could not encode MQTT discovery config for \(self)")
            print(error)
        }
    }
}
