//
//  Sensor.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/20/21.
//


import Foundation
import OpenCombine
import MQTT

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum Room: CustomStringConvertible, Decodable, Hashable, Comparable {
    
    case room(String)
    case æther
    
    public var description: String {
        switch self {
        case let .room(name):
            return name
        case .æther:
            return "Æther"
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        self = .room(try container.decode(String.self))
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }
    
    var slug: String {
        description.slug
    }
    
    var sensorName: String {
        "\(slug)_occupancy_count"
    }
    
    var mqttTopic: String {
        "homeassistant/sensor/swift-occupancy/\(sensorName)"
    }
    
    var publishStateChanges: Bool {
        switch self {
        case .room:
            return true
        case .æther:
            return false
        }
    }
    
    func publishSensorConfig(_ client:  LightMQTT) {
        let config: [String: Any] = [
            "name": "\(description) Occupancy Count",
            "unique_id": sensorName,
            "state_topic": "\(mqttTopic)/state",
            "unit_of_measurement": "person",
            "icon": 0.icon,
            "device": [
                "name": "\(slug)-occupancy-sensor",
                "model": "AMG88xx",
                "manufacturer": "Emory Dunn",
                "identifiers": "\(slug)-occupancy-sensor"
            ]
        ]
        
        do {
            let payload = try JSONSerialization.data(withJSONObject: config, options: [])
//            client.publish(topic: "\(mqttTopic)/config", retain: true, qos: .atLeastOnce, payload: payload)
            client.publish(to: "\(mqttTopic)/config", message: payload)
            print("Published MQTT discovery topic for \(self)")
        } catch {
            print("Could not encode MQTT discovery config for \(self)")
            print(error)
        }

    }
    
    func publishState(_ count: Int, with client:  LightMQTT) {
        client.publish(to: "\(mqttTopic)/state", message: String(describing: count).data(using: .utf8))
//        client.publish(topic: "\(mqttTopic)/state", retain: false, qos: .atLeastOnce, payload: String(describing: count))
    }
    
    
    /// Subscribe to the state of this room.
    /// - Parameter client: The MQTT client.
    /// - Returns: A Publisher indicating the number of people in the room. 
    func subscribe(with client: LightMQTT) -> AnyPublisher<Int, Never> {
        client
            .packetPublisher()
            .subscribe(to: "\(mqttTopic)/state")
//            .filterForSubscriptions()
//            .compactMap { packet in
//                String(data: packet.payload, encoding: .utf8)
//            }
            .compactMap {
                Int($0)
            }
            .eraseToAnyPublisher()
    }
}

public class House {
    @OpenCombine.Published public private(set) var rooms: [Room: Int]
    var tokens: [AnyCancellable] = []
    
    public init(rooms: [Room: Int]) {
        self.rooms = rooms
    }
    
    public init(rooms: [Room]) {
        self.rooms = [Room: Int]()
        
        rooms.forEach {
            self.rooms[$0] = 0
        }
    }
    
    public init(sensors: [MQTTSensor]) {
        self.rooms = [Room: Int]()
        sensors.forEach {
            self.rooms[$0.topName] = 0
            self.rooms[$0.bottomName] = 0
        }
    }
    
    public subscript(_ room: Room) -> Int {
        get {
            rooms[room, default: 0]
        }
        set {
            rooms[room] = max(0, newValue)
        }
    }

}

public struct OccupancyChange: CustomStringConvertible {
    
//    public static let `default` = OccupancyChange(action: "No Action", delta: [:])
    
    public let topRoom: Room
    public let bottomRoom: Room
    public let direction: Direction
    
    public init(_ direction: Direction, topRoom: Room, bottomRoom: Room) {
        self.direction = direction
        self.topRoom = topRoom
        self.bottomRoom = bottomRoom
    }

    public var description: String {
        switch direction {
        case .toTop:
            return "\(bottomRoom) -> \(topRoom)"
        case .toBottom:
            return "\(topRoom) -> \(bottomRoom)"
        }
    }
    
    func update(_ house: House) {
        switch direction {
        case .toTop:
            house[topRoom] += 1
            house[bottomRoom] -= 1
        case .toBottom:
            house[topRoom] -= 1
            house[bottomRoom] += 1
        }
    }
}

public enum Direction {
    case toTop
    case toBottom
}
