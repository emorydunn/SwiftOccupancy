//
//  Sensor.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/20/21.
//


import Foundation
import OpenCombineShim

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
    
    var publishStateChanges: Bool {
        switch self {
        case .room:
            return true
        case .æther:
            return false
        }
    }
}

public class House: ObservableObject {
    @Published public private(set) var rooms: [Room: Int]
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
