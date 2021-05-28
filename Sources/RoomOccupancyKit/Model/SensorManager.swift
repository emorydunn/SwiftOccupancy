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
    
//    public var sensors: [Sensor]
    public var sensors: [MQTTSensor] = []
    public let mqttBroker: HAMQTTConfig
    public let homeAssistant: HAConfig?
    
    @Published public private(set) var occupancy: [Room: Int]
//    public private(set) var occupancy: [Room: Int]
//    @Published public var occupancyUpdates: OccupancyUpdate = OccupancyChange.default
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
        
    }
    
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
            .subscribe(topic: "swift-occupancy/sensor/+", qos: .atMostOnce)
            .filterForSubscriptions()
            .eraseToAnyPublisher()
    }
    
    public func publishToHA() {
        guard let config = homeAssistant else {
            print("No Home Assistant config provided, updates will not be published.")
            return
        }
        
        print("Publishing changes to Home Assistant")
        $deltasToSend
            .print("New Change")
            .publishtoHomeAssistant(using: config)
            .sink {
                print("HA Completion", $0)
            } receiveValue: { value in
                guard value.statusCode != 200 else { return }
                print("ERROR: \(value.statusCode)")
            }
            .store(in: &tokens)
    
    }
    
//    public func publishToHomeAssistant(using config: HAConfig) {
//        // Publish the changed values
//        $occupancy
//            .map { $0.changes }
//            .flatMap {
//                $0.publisher
//            }
//            .print("Sending HA State")
//            .filter { $0.key.publishStateChanges }
//            .map { change -> URLRequest in
//                var request = URLRequest(url: homeAssistant.url.appendingPathComponent("/api/states/sensor.\(change.key.slug)_occupancy_count"))
//                request.httpMethod = "POST"
//                request.setValue("Bearer \(homeAssistant.token)", forHTTPHeaderField: "Authorization")
//
//                let jsonBody: [String: Any] = [
//                    "state": change.value,
//                    "attributes": [
//                        "friendly_name": "\(change.key) Occupancy",
//                        "unit_of_measurement": self.unit(for: change.value),
//                        "icon": self.icon(for: change.value)
//                    ]
//                ]
//
//                request.httpBody = try? JSONSerialization.data(withJSONObject: jsonBody, options: [])
//
//                return request
//            }
//            .flatMap { request -> URLSession.DataTaskPublisher in
//                URLSession.shared.dataTaskPublisher(for: request)
//            }
//            .retry(3)
//            .compactMap { element -> HTTPURLResponse? in
//                element.response as? HTTPURLResponse
//            }
//            .sink {
//                print($0)
//            } receiveValue: { value in
//                guard value.statusCode != 200 else { return }
//                print("ERROR: \(value.statusCode)")
//            }
//            .store(in: &tokens)
//    }
//
    
//
//    public func monitorSensors() {
//
//        sensors.forEach {
//            // Begin monitoring data
//            $0.monitorData()
//        }
//
//        let changes = sensors.publisher
//            .flatMap { $0.$currentDelta }
//            .applyOccupancyDelta(to: occupancy)
//            .print("SensorManager Sub")
//            .share()
//
//        // Update the occupancy
////        changes
////            .map { $0.newValues }
////            .removeDuplicates()
////            .assign(to: &$occupancy)
//
//        guard let homeAssistant = homeAssistant else {
//            print("No Home Assistant Config Provided")
//            return
//        }
//
//        // Publish the changed values
//        changes
//            .map { $0.changes }
//            .flatMap {
//                $0.publisher
//            }
//            .print("Sending HA State")
//            .filter { $0.key.publishStateChanges }
//            .map { change -> URLRequest in
//                var request = URLRequest(url: homeAssistant.url.appendingPathComponent("/api/states/sensor.\(change.key.slug)_occupancy_count"))
//                request.httpMethod = "POST"
//                request.setValue("Bearer \(homeAssistant.token)", forHTTPHeaderField: "Authorization")
//
//                let jsonBody: [String: Any] = [
//                    "state": change.value,
//                    "attributes": [
//                        "friendly_name": "\(change.key) Occupancy",
//                        "unit_of_measurement": self.unit(for: change.value),
//                        "icon": self.icon(for: change.value)
//                    ]
//                ]
//
//                request.httpBody = try? JSONSerialization.data(withJSONObject: jsonBody, options: [])
//
//                return request
//            }
//            .flatMap { request -> URLSession.DataTaskPublisher in
//                URLSession.shared.dataTaskPublisher(for: request)
//            }
//            .retry(3)
//            .compactMap { element -> HTTPURLResponse? in
//                element.response as? HTTPURLResponse
//            }
//            .sink {
//                print($0)
//            } receiveValue: { value in
//                guard value.statusCode != 200 else { return }
//                print("ERROR: \(value.statusCode)")
//            }
//            .store(in: &tokens)
//
//
//    }
//
//    func publishToHomeAssistant() {
//
//    }
//
//    func unit(for count: Int) -> String {
//        count == 1 ? "person" : "people"
//    }
//
//    func icon(for count: Int) -> String {
//        switch count {
//        case 0:
//            return "mdi:account-outline"
//        case 1:
//            return "mdi:account"
//        case 2:
//            return "mdi:account-multiple"
//        default:
//            return "mdi:account-group"
//        }
//    }
        
}



struct OccupancyUpdate {
    let newValues: [Room: Int]
    let changes: [Room: Int]
}
