//
//  SensorManager.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/17/21.
//

import Foundation
import OpenCombine
import MQTT

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public class SensorManager: Decodable {
    
    public var sensors: [MQTTSensor] = []
    public let mqttBroker: HAMQTTConfig
    public let homeAssistant: HAConfig?
    
    /// The current room occupancy counts.
    public private(set) var occupancy: House
    
    /// Occupancy changes to publish
//    @Published var deltasToSend = [Room: Int]()
    
    var tokens: [AnyCancellable] = []
    
    public init(sensors: [MQTTSensor], broker: HAMQTTConfig, haConfig: HAConfig?, occupancy: House? = nil) {
        self.sensors = sensors
        self.mqttBroker = broker
        self.homeAssistant = haConfig
        
        // Use the given occupancy counts,
        // otherwise set all rooms to 0
        if let occupancy = occupancy {
            self.occupancy = occupancy
        } else {
            self.occupancy = House(sensors: sensors)
        }

    }
    
    static func manager(configFile: URL) -> SensorManager {
        // Parse the file
        let data: Data
        do {
            data = try Data(contentsOf: configFile)
        } catch {
            print("There was a problem reading \(configFile.path).")
            print(error.localizedDescription)
            exit(1)
        }

        do {
            return try JSONDecoder().decode(SensorManager.self, from: data)

        } catch {
            print("There was a problem decoding the config file.")
            print(error)
            exit(1)
        }
    }
    
    // MARK: Codable
    public enum CodingKeys: String, CodingKey {
        case sensors, mqtt, homeAssistant
    }
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.sensors = try container.decode([MQTTSensor].self, forKey: .sensors)
        self.mqttBroker = try container.decode(HAMQTTConfig.self, forKey: .mqtt)
        self.homeAssistant = try container.decodeIfPresent(HAConfig.self, forKey: .homeAssistant) ?? HAConfig.haAddOn

        self.occupancy = House(sensors: sensors)
        
    }
    
    /// Create and MQTT client and subscribe to the sensor topic.
    public func monitorMQTT(publishToHA: Bool) {
        // Begin monitoring data
        let client = mqttBroker.makeClient()
        
//        connectToClient(client)
//            .catch { error -> AnyPublisher<PublishPacket, Error> in
//                print("MQTT Error:", error)
//                client.disconnect()
//                return self.connectToClient(client)
//            }
//            .share()
//            .mapToChange(using: sensors)
//            .applyOccupancy(to: occupancy)
        
        guard publishToHA else { return }
        
//        occupancy.rooms.keys.forEach {
//            $0.publishSensorConfig(client)
//        }
        
        print("Publishing changes to Home Assistant")
        occupancy.$rooms
            .filter { !$0.isEmpty }
            .publishtoHomeAssistant(using: client)
            .store(in: &tokens)
        
    }

    func connectToClient(_ client: MQTTClient) -> AnyPublisher<PublishPacket, Error> {
        return client
            .packetPublisher()
            .subscribe(topic: "swift-occupancy/sensor/+", qos: .atLeastOnce)
            .filterForSubscriptions()
            .eraseToAnyPublisher()
    }

    
    /// Subscribe to occupancy changes and send them to the Home Assistant HTTP API.
    public func publishToHA() {
        guard let config = homeAssistant else {
            print("No Home Assistant config provided, updates will not be published.")
            return
        }
        
        print("Publishing changes to Home Assistant")
//        occupancy.$rooms
//            .filter { !$0.isEmpty }
//            .publishtoHomeAssistant(using: config)
//            .sink {
//                print("HA Completion", $0)
//            } receiveValue: { value in
//                guard value.statusCode != 200 else { return }
//                print("ERROR: \(value.statusCode)")
//            }
//            .store(in: &tokens)
        
//        sensors.forEach { sensor in
//            sensor
//                .$sensorSVG
//                .publishState(sensor.name, domain: "camera", using: config)
//                .sink {
//                    print("HA Completion", $0)
//                } receiveValue: { value in
//                    guard value.statusCode != 200 else { return }
//                    print("ERROR: \(value.statusCode)")
//                }
//                .store(in: &tokens)
//
//        }
        
        print("Sending initial empty state:", occupancy)
//        deltasToSend = occupancy
    
    }
     
}
