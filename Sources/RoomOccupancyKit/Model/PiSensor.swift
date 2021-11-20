//
//  PiSensor.swift
//  
//
//  Created by Emory Dunn on 9/12/21.
//

import Foundation
import AMG88xx
import SwiftyGPIO
import OpenCombine
import OpenCombineFoundation
import MQTT
import Cairo
import Silica

public class PiSensor: Decodable {
    
    public var id: String {
        "\(topRoom) / \(bottomRoom)"
    }
    
    public var clientID: String {
        "\(topRoom)-\(bottomRoom)"
    }
    
    public var topRoom: Room = .æther
    public var bottomRoom: Room = .æther
    
    public var deltaThreshold: Float = 2
    public var minClusterSize: Int = 10
    public var minWidth: Int = 3
    public var minHeight: Int = 3
    public var averageFrameCount: Int = 2
    
    public enum CodingKeys: String, CodingKey {
        case topRoom, bottomRoom
        case deltaThreshold
        case minClusterSize
        case minWidth
        case minHeight
        case averageFrameCount
    }
    
    public init(topRoom: Room,
                bottomRoom: Room,
                deltaThreshold: Float = 2,
                minClusterSize: Int = 10,
                minWidth: Int = 3,
                minHeight: Int = 3,
                averageFrameCount: Int = 2) {
        
        self.topRoom = topRoom
        self.bottomRoom = bottomRoom
        self.deltaThreshold = deltaThreshold
        self.minClusterSize = minClusterSize
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.averageFrameCount = averageFrameCount
    }
    
    @OpenCombine.Published public var sensorData: SensorPayload?
    @OpenCombine.Published public var currentCluster: Cluster?
    @OpenCombine.Published public var averageTemp: Float = 22.0
    
    @OpenCombine.Published public var topRoomCount: Int = 0
    @OpenCombine.Published public var bottomRoomCount: Int = 0
    
    @OpenCombine.Published public var thermistorTemperature: Float = 0
    
    var tokens: [AnyCancellable] = []
    
    let imageQueue = DispatchQueue(label: "CameraPub")
    
    var mqttTopic: String { "homeassistant/camera/swift-occupancy/\(clientID)" }
    var statusTopic: String { "swift-occupancy/sensor/\(clientID)/status" }
    var stateTopic: String { "\(mqttTopic)/state" }
    var configTopic: String { "\(mqttTopic)/config" }
    
    
    func statusMessage(_ status: Bool) -> PublishMessage {
        PublishMessage(topic: statusTopic, payload: status ? "online" : "offline", retain: false, qos: .atMostOnce)
    }

    func monitorRooms(from client: MQTTClient) {
        
        let mqttPublisher = client.sharedMessagesPublisher { client in
            
            self.topRoom.subscribe(with: client)
            self.bottomRoom.subscribe(with: client)
            
            self.topRoom.publishSensorConfig(client, availabilityTopic: self.statusTopic)
            self.bottomRoom.publishSensorConfig(client, availabilityTopic: self.statusTopic)
            
            self.publishSensorConfig(client)
            self.publishCameraConfig(client)
            
            client.publish(message: self.statusMessage(true), identifier: nil)

        }
        
        $thermistorTemperature
            .collect(10)
            .map { values -> Float in
                // Average the value
                values.reduce(0, +) / Float(values.count)
            }
            .map {
                String(format: "%.02f", $0)
            }
            .sink { temp in
                let topic = "homeassistant/sensor/swift-occupancy/\(self.clientID)/state"
                client.publish(topic: topic, retain: false, qos: .atMostOnce, payload: temp, identifier: nil)
            }
            .store(in: &tokens)

        $sensorData
            .compactMap { $0 }
            .tryMap {
                let surface = try $0.drawImage()
                
                return try surface.writePNG()
            }
            .replaceError(with: nil)
            .compactMap { $0 }
            .sink { data in
                client.publish(topic: self.stateTopic, retain: false, qos: .atMostOnce, payload: data, identifier: nil)
            }
            .store(in: &tokens)
        
        topRoom
            .occupancy(mqttPublisher)
            .replaceError(with: 0)
            .assign(to: &$topRoomCount)

        $topRoomCount
            .removeDuplicates()
            .filter { _ in client.state == .connected }
            .print(topRoom.sensorName)
            .sink { value in
                self.topRoom.publishState(value, with: client)
            }
            .store(in: &tokens)

        bottomRoom
            .occupancy(mqttPublisher)
            .replaceError(with: 0)
            .assign(to: &$bottomRoomCount)

        $bottomRoomCount
            .removeDuplicates()
            .filter { _ in client.state == .connected }
            .print(topRoom.sensorName)
            .sink { value in
                self.bottomRoom.publishState(value, with: client)
            }
            .store(in: &tokens)
    }
    
    func debugSensor(with client: MQTTClient) {
        $sensorData
            .compactMap { $0 }
//            .logSensorData()
            .sink { data in
                client.publish(topic: "swift-occupancy/sensor/\(self.clientID)/data", retain: false, qos: .atMostOnce, payload: data, identifier: nil)
            }
            .store(in: &tokens)

    }
    
    
    func monitorSensor(on interface: I2CInterface) {
        // Create the sensor
        let sensor = AMG88(interface)
        
        // Monitor the sensor
        Timer
            .publish(every: 0.1, on: .main, in: .default)
            .autoconnect()
            .map { _ in sensor.readThermistor() }
            .assign(to: &$thermistorTemperature)
        
        Timer
            .publish(every: 0.1, on: .main, in: .default)
            .autoconnect().map { _ in
                sensor.readPixels()
            }
            // Map to SensorPayload
            .tryMap { pixels in
                try SensorPayload(data: pixels)
            }
            .breakpointOnError()
            .replaceError(with: nil)
//            .averageFrames(averageFrameCount)
            .assign(to: &$sensorData)
        
        // Collect rolling average temp
        $sensorData
            .compactMap { $0 }
            .compactMap { $0.mean }
            .collect(100)
            .map { temps in
                (temps.reduce(0, +) / Float(temps.count)).rounded()
            }
            .assign(to: &$averageTemp)
        
        $sensorData
            .compactMap { $0 }
            .findRelevantPixels(averageTemperature: averageTemp, deltaThreshold: deltaThreshold)
            .clusterHottestPixels()
            .map {
                guard let cluster = $0 else { return nil }
                
                // Ensure the cluster meets the min size
                guard cluster.size >= self.minClusterSize else {
                    return nil
                }
                
                let box = cluster.boundingBox()
                let width = box.maxX - box.minX
                let height = box.maxY - box.minY

                // Ensure the cluster has minimum dimensions
                guard width >= self.minWidth && height >= self.minWidth else {
                    return nil
                }

                return cluster
            }
            .assign(to: &$currentCluster)
        
        $currentCluster
            .compactMap { $0 }
            .logGrid()
            .pairwise()
            .parseDelta(top: topRoom, bottom: bottomRoom)
            .sink { change in
                switch change.direction {
                case .toTop:
                    self.topRoomCount += 1
                    self.bottomRoomCount = max(0, self.bottomRoomCount - 1)
                case .toBottom:
                    self.topRoomCount = max(0, self.topRoomCount - 1)
                    self.bottomRoomCount += 1
                }
            }
            .store(in: &tokens)
        
    }
    
    func publishSensorConfig(_ client:  MQTTClient) {
        
        let mqttTopic = "homeassistant/sensor/swift-occupancy/\(clientID)"
        
        let config: [String: Any] = [
            "name": "\(id) Temperature",
            "unique_id": "\(clientID)-temperature",
            "state_class": "measurement",
            "unit_of_measurement": "ºC",
            "icon": "mdi:thermometer",
            "state_topic": "\(mqttTopic)/state",
            "device": [
                "name": "\(id) Thermopile",
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
    
    func publishCameraConfig(_ client:  MQTTClient) {
        
        let config: [String: Any] = [
            "name": "\(id) Heatmap",
            "unique_id": "\(clientID)-thermopile",
            "topic": "\(mqttTopic)/state",
            "device": [
                "name": "\(id) Thermopile",
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
