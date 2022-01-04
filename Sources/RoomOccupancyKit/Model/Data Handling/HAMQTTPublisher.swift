//
//  HAMQTTPublisher.swift
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
    
    public var clientID: String { counter.id }
    
    public var publishImage: Bool
    
    // MQTT Topics
    var mqttTopic: String { "homeassistant/camera/swift-occupancy/\(clientID)" }
    var statusTopic: String { "swift-occupancy/sensor/\(clientID)/status" }
    var stateTopic: String { "\(mqttTopic)/state" }
    var configTopic: String { "\(mqttTopic)/config" }
    
    public init(sensor: AMGSensorProtocol, client: AsyncMQTTClient, counter: OccupancyCounter, publishImage: Bool) {
        self.sensor = sensor
        self.client = client
        self.counter = counter
        self.publishImage = publishImage
    }
    
    public init(sensor: AMGSensorProtocol, client: AsyncMQTTClient, topRoom: Room = .æther, bottomRoom: Room = .æther, publishImage: Bool) {
        self.sensor = sensor
        self.client = client
        self.counter = OccupancyCounter(topRoom: topRoom, bottomRoom: bottomRoom)
        self.publishImage = publishImage
    }
    
    public init(board: SupportedBoard, client: AsyncMQTTClient, counter: OccupancyCounter, publishImage: Bool) {
        self.sensor = I2CAMGSensor(board: board)
        self.client = client
        self.counter = counter
        self.publishImage = publishImage
    }
    
    public init(board: SupportedBoard, client: AsyncMQTTClient, topRoom: Room = .æther, bottomRoom: Room = .æther, publishImage: Bool) {
        self.sensor = I2CAMGSensor(board: board)
        self.client = client
        self.counter = OccupancyCounter(topRoom: topRoom, bottomRoom: bottomRoom)
        self.publishImage = publishImage
    }
    
    public func setupHA() {
        
        // Publish main sensor config
        publishSensorConfig(client)
        publishCameraConfig(client)
        
        // Publish room sensor configs
        counter.topRoom.publishSensorConfig(client.client, availabilityTopic: self.statusTopic)
        counter.bottomRoom.publishSensorConfig(client.client, availabilityTopic: self.statusTopic)
        
        // Publish HA status
        print("Publishing sensor status message")
        client.publish(message: statusMessage(true))
        
//        client.client.willMessage = statusMessage(false)
    }
    
    public func publishData() async throws {
        
        await counter.subscribeToMQTTCounts(with: client)
        
        for try await data in sensor.data {
            
            // Count changes and publish them
            Task {
                if let change = try counter.countChanges(using: data) {
                    counter.publishChange(change, with: client)
                }
            }
            
            if publishImage {
                // Publish the sensor image
                Task {
                    let image = try data.drawImage(cluster: counter.currentCluster).writePNG()
                    client.publish(topic: self.stateTopic, retain: false, qos: .atMostOnce, payload: image)
                }
            }
            
            
            // Publish the thermistor temp
            Task {
                let temp = String(format: "%.02f", data.thermistorTemperature)
                let topic = "homeassistant/sensor/swift-occupancy/\(self.clientID)/state"
                client.publish(topic: topic, retain: false, qos: .atMostOnce, payload: temp, identifier: nil)
            }
        }

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

extension HAMQTTPublisher: CustomStringConvertible {
    public var description: String {
        "HA MQTT Publisher \(counter.topRoom) / \(counter.bottomRoom)"
    }
}
