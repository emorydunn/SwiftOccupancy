//
//  MQTTSensor.swift
//  
//
//  Created by Emory Dunn on 5/25/21.
//

import Foundation
import OpenCombineShim
import MQTT

@propertyWrapper
struct RoomCount {
    var count: Int
    
    init(count: Int) {
        self.count = count
    }
    
    public var wrappedValue: Int {
        get {
            count
        }
        
        set {
            count = max(0, newValue)
        }
    }
}

public class MQTTSensor: ObservableObject, Decodable, Identifiable {
    
    public enum CodingKeys: String, CodingKey {
        case name, topName, bottomName, deltaThreshold, minClusterSize, averageFrameCount, minWidth, minHeight
    }
    
    public let name: String
    
    public var id: String { name }
    
    public let topName: Room
    public let bottomName: Room
    
//    @RoomCount public var topRoomCount: Int = 0
//    @RoomCount public var bottomRoomCount: Int = 0
    
    public var deltaThreshold: Double
    public var minClusterSize: Int
    public var minWidth: Int
    public var minHeight: Int
    public var averageFrameCount: Int
    
    @Published public var sensorData: SensorPayload?
    @Published public var currentCluster: Cluster?
    @Published public var averageTemp: Double = 22.0
    @Published public var sensorSVG: String = ""
//    @Published public var lastAction: Direction?
    
    var tokens: [AnyCancellable] = []
    
    public init(_ sensorName: String,
                topName: Room = .room("Top Room"),
                bottomName: Room = .room("Bottom Room"),
                deltaThreshold: Double = 2,
                minClusterSize: Int = 10,
                minWidth: Int = 3,
                minHeight: Int = 3,
                averageFrameCount: Int = 2) {
        self.name = sensorName
        self.topName = topName
        self.bottomName = bottomName
        self.deltaThreshold = deltaThreshold
        self.minClusterSize = minClusterSize
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.averageFrameCount = averageFrameCount
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Primary Info
        self.name = try container.decode(String.self, forKey: .name)
        self.topName = try container.decodeIfPresent(Room.self, forKey: .topName) ?? .æther
        self.bottomName = try container.decodeIfPresent(Room.self, forKey: .bottomName) ?? .æther

        // Sensor Config
        self.deltaThreshold = try container.decodeIfPresent(Double.self, forKey: .deltaThreshold) ?? 2
        self.minClusterSize = try container.decodeIfPresent(Int.self, forKey: .minClusterSize) ?? 10
        self.minWidth = try container.decodeIfPresent(Int.self, forKey: .minWidth) ?? 3
        self.minHeight = try container.decodeIfPresent(Int.self, forKey: .minHeight) ?? 3
        self.averageFrameCount = try container.decodeIfPresent(Int.self, forKey: .averageFrameCount) ?? 2

    }
    
    func parseData(from packets: AnyPublisher<PublishPacket, Error>, assigningTo published: inout Published<OccupancyChange>.Publisher) {
        self.monitorData(from: packets).assign(to: &published)
    }
    
//    func monitorData(from packets: AnyPublisher<PublishPacket, Error>) -> AnyPublisher<Direction, Never> {
//    }
    
    func monitorData(from packets: AnyPublisher<PublishPacket, Error>) -> AnyPublisher<OccupancyChange, Never> {
        
        packets
            // Filter packets for this sensor
            .filter { packet in
                packet.topic.hasSuffix(self.name)
            }
            // Map to SensorPayload
            .map { packet in
                SensorPayload(sensor: self.name, data: packet.payload)
            }
            .breakpointOnError()
            .replaceError(with: nil)
            .averageFrames(averageFrameCount)
            .assign(to: &$sensorData)

        // Collect rolling average temp
        $sensorData
            .compactMap { $0 }
            .compactMap { $0.mean }
            .collect(100)
            .map { temps in
                (temps.reduce(0, +) / Double(temps.count)).rounded()
            }
            .assign(to: &$averageTemp)
        
//        $sensorData
//            .compactMap { $0?.createImage() }
//            .assign(to: &$sensorSVG)
            
        // Process Clusters
        $sensorData
            .compactMap { $0 }
            .findRelevantPixels(averageTemperature: averageTemp, deltaThreshold: deltaThreshold)
            .clusterHotestPixels()
            .map {
                guard let cluster = $0 else { return nil }
                
                // Ensure the cluster meets the min size
                guard cluster.size >= self.minClusterSize else {
                    return nil
                }
                
                let box = cluster.boundingBox()
                let width = box.maxX - box.minX
                let height = box.maxY - box.minY

                // Ensure the cluser has minimum dimensions
                guard width >= self.minWidth && height >= self.minWidth else {
                    return nil
                }

                return cluster
            }
            .assign(to: &$currentCluster)
            
        return $currentCluster
            .compactMap { $0 }
            .logGrid()
            .removeDuplicates()
            .pairwise()
            .parseDelta(top: topName, bottom: bottomName)
//            .filter { $0.hasAction }
            .eraseToAnyPublisher()
    
    }
    
    
}

