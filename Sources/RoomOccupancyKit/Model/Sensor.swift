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
    
    var publishStateChanges: Bool {
        switch self {
        case .room:
            return true
        case .æther:
            return false
        }
    }
}

public struct OccupancyChange: CustomStringConvertible {
    
    public static let `default` = OccupancyChange(action: "No Action", delta: [:])
    
    public let action: String
    public let delta: [Room: Int]
    public let absolute: Bool
    
    public init(action: String, delta: [Room: Int], absolute: Bool = false) {
        self.action = action
        self.delta = delta
        self.absolute = absolute
    }

    public var description: String {
        if absolute {
            return "\(action) -> Absolute \(delta)"
        }
        return "\(action) -> \(delta)"
    }
    
    public var hasAction: Bool {
        !delta.isEmpty
    }
}

enum Direction {
    case toTop
    case toBottom
}
