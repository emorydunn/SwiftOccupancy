//
//  SensorManager.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/17/21.
//

import Foundation
import OpenCombineShim
import MQTT

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public class SensorManager: ObservableObject, Decodable {
    
    public var sensors: [MQTTSensor] = []
    public let mqttBroker: HAMQTTConfig
    public let homeAssistant: HAConfig?
    
    /// The current room occupancy counts.
    @Published public private(set) var occupancy: [Room: Int]
    
    /// Occupancy changes to publish
    @Published var deltasToSend = [Room: Int]()
    
    var tokens: [AnyCancellable] = []
    
    public init(sensors: [MQTTSensor], broker: HAMQTTConfig, haConfig: HAConfig?, occupancy: [Room: Int]? = nil) {
        self.sensors = sensors
        self.mqttBroker = broker
        self.homeAssistant = haConfig
        
        // Use the given occupancy counts,
        // otherwise set all rooms to 0
        if let occupancy = occupancy {
            self.occupancy = occupancy
        } else {
            self.occupancy = [:]
            sensors.forEach {
                self.occupancy[$0.topName] = 0
                self.occupancy[$0.bottomName] = 0
            }
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
        self.occupancy = [:]
        
        sensors.forEach {
            self.occupancy[$0.topName] = 0
            self.occupancy[$0.bottomName] = 0
        }
        
    }
    
    /// Create and MQTT client and subscribe to the sensor topic.
    public func monitorMQTT() {
        // Begin monitoring data
        let client = mqttBroker.makeClient()
        
        connectToClient(client)
            .catch { error -> AnyPublisher<PublishPacket, Error> in
                print("MQTT Error:", error)
                client.disconnect()
                return self.connectToClient(client)
            }
            .share()
            .mapToChange(using: sensors)
            .applyOccupancyDelta(to: &occupancy)
            .assign(to: &$deltasToSend)

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
        $deltasToSend
            .filter { !$0.isEmpty }
            .print("New Change")
            .publishtoHomeAssistant(using: config)
            .sink {
                print("HA Completion", $0)
            } receiveValue: { value in
                guard value.statusCode != 200 else { return }
                print("ERROR: \(value.statusCode)")
            }
            .store(in: &tokens)
        print("Sending initial empty state:", occupancy)
        deltasToSend = occupancy
    
    }
     
}
