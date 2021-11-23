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

public enum Room: CustomStringConvertible, Decodable {
    
    case room(String)
    case æther
    
    /// Convenience for Æther
    public static let aether: Room = .æther
    
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
    
    var slug: String {
        description.slug
    }
    
    var sensorName: String {
        "\(slug)_occupancy_count"
    }
    
    var mqttTopic: String {
        "homeassistant/sensor/swift-occupancy/\(sensorName)"
    }
    
    var stateTopic: String {
        "\(mqttTopic)/state"
    }
    
    var publishStateChanges: Bool {
        switch self {
        case .room:
            return true
        case .æther:
            return false
        }
    }
    
    func publishSensorConfig(_ client:  MQTTClient, availabilityTopic: String) {
        let config: [String: Any] = [
            "name": "\(description) Occupancy Count",
            "unique_id": sensorName,
            "state_topic": stateTopic,
            "unit_of_measurement": "person",
            "icon": 0.icon,
            "device": [
                "name": "\(slug)-occupancy-sensor",
                "model": "AMG88xx",
                "manufacturer": "Emory Dunn",
                "identifiers": "\(slug)-occupancy-sensor"
            ],
            "availability": [
                "topic": availabilityTopic
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
    
    func publishState(_ count: Int, with client:  MQTTClient) {
        client.publish(topic: stateTopic, retain: true, qos: .atLeastOnce, payload: String(describing: count))
    }

    
    /// Subscribe to the state of this room.
    /// - Parameter client: The MQTT client.
    /// - Returns: A Publisher indicating the number of people in the room.
    func subscribe(with client: MQTTClient) {
        print("Subscribing to", stateTopic)
        client.subscribe(topic: stateTopic, qos: .atMostOnce, identifier: nil)
    }
    
    /// Subscribe to the state of this room.
    /// - Parameter client: The MQTT client.
    /// - Returns: A Publisher indicating the number of people in the room.
    func occupancy(_ pub: AnyPublisher<PublishPacket, Error>) -> AnyPublisher<Int, Never> {
        pub
            .filter(forTopic: stateTopic)
            .compactMap { message in
                String(data: message.payload, encoding: .utf8)
            }
            .compactMap {
                Int($0)
            }
            .replaceError(with: 0)
            .eraseToAnyPublisher()
    }
}

extension Room: Comparable, Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.description < rhs.description
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
    
//    public init(sensors: [MQTTSensor]) {
//        self.rooms = [Room: Int]()
//        sensors.forEach {
//            self.rooms[$0.topName] = 0
//            self.rooms[$0.bottomName] = 0
//        }
//    }
    
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

    public let topRoom: Room
    public let bottomRoom: Room
    public let direction: Direction
    
    public init(_ direction: Direction, topRoom: Room, bottomRoom: Room) {
        self.direction = direction
        self.topRoom = topRoom
        self.bottomRoom = bottomRoom
    }
    
    public init(currentCluster: Cluster, previousCluster: Cluster, topRoom: Room, bottomRoom: Room) {
        
        // Parse cluster delta
        switch (previousCluster.clusterSide, currentCluster.clusterSide) {
        case (.bottom, .bottom):
            // Same side, nothing to do
            self = OccupancyChange(.none, topRoom: topRoom, bottomRoom: bottomRoom)
        case (.top, .top):
            // Same side, nothing to do
            self = OccupancyChange(.none, topRoom: topRoom, bottomRoom: bottomRoom)
        case (.bottom, .top):
            // Moved from bottom to top
            self = OccupancyChange(.toTop, topRoom: topRoom, bottomRoom: bottomRoom)
        case (.top, .bottom):
            // Moved from top to bottom
            self = OccupancyChange(.toBottom, topRoom: topRoom, bottomRoom: bottomRoom)
        }
    }

    public var description: String {
        switch direction {
        case .toTop:
            return "B \(bottomRoom) -> T \(topRoom)"
        case .toBottom:
            return "T \(topRoom) -> B \(bottomRoom)"
        case .none:
            return "T \(topRoom) == B \(bottomRoom)"
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
        case .none:
            break
        }
    }
    
    func update(topCount: inout Int, bottomCount: inout Int) {
        switch direction {
        case .toTop:
            topCount += 1
            bottomCount = max(0, bottomCount - 1)
        case .toBottom:
            topCount = max(0, topCount - 1)
            bottomCount += 1
        case .none:
            break
        }
    }
}

public enum Direction {
    case toTop
    case toBottom
    case none
}
