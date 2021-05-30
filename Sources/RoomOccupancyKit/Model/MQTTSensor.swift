//
//  MQTTSensor.swift
//  
//
//  Created by Emory Dunn on 5/25/21.
//

import Foundation
import OpenCombineShim
import MQTT

public class MQTTSensor: ObservableObject, Decodable, Identifiable {
    
    public enum CodingKeys: String, CodingKey {
        case name, topName, bottomName, deltaThreshold, minClusterSize, averageFrameCount
    }
    
    public let name: String
    
    public var id: String { name }
    
    public let topName: Room
    public let bottomName: Room
    
    public var deltaThreshold: Double = 2
    public var minClusterSize: Int = 10
    public var averageFrameCount: Int = 2
    
    @Published public var sensorData: SensorPayload?// = SensorPayload(sensor: "Fake Sensor", data: [])
    @Published public var currentCluster: Cluster?
//    @Published public var currentDelta: OccupancyChange = OccupancyChange.default
    @Published public var averageTemp: Double = 22.0 //CurrentValueSubject<Double, Never>(21)
    
    var tokens: [AnyCancellable] = []
    
    public init(_ sensorName: String, topName: Room = .room("Top Room"), bottomName: Room = .room("Bottom Room")) {
        self.name = sensorName
        self.topName = topName
        self.bottomName = bottomName
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
        self.averageFrameCount = try container.decodeIfPresent(Int.self, forKey: .averageFrameCount) ?? 2

    }
    
    func parseData(from packets: AnyPublisher<PublishPacket, Error>, assigningTo published: inout Published<OccupancyChange>.Publisher) {
        self.monitorData(from: packets).assign(to: &published)
    }
    
    
    func monitorData(from packets: AnyPublisher<PublishPacket, Error>) -> AnyPublisher<OccupancyChange, Never> {
        
        packets
            // Filter packets for this sensor
            .filter { packet in
                packet.topic.hasSuffix(self.name)
            }
//            .map { packet -> PublishPacket in
//                Swift.print(self.name, packet.topic)
//                return packet
//            }
            // Map to SensorPayload
            .map { packet in
                SensorPayload(sensor: self.name, data: packet.payload)
            }
            .breakpointOnError()
            .replaceError(with: nil)
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
            
        // Process Clusters
        $sensorData
            .compactMap { $0 }
            .averageFrames(averageFrameCount)
            .findRelevantPixels(averageTemperature: averageTemp, deltaThreshold: deltaThreshold)
            .clusterHotestPixels()
            .filter { $0?.size ?? 0 >= self.minClusterSize }
//            .clusterPixels()
//            .map { $0.largest(minSize: self.minClusterSize) } // Map the clusters to the largest
//            .filter {
//                guard let cluster = $0 else { return false }
//                let box = cluster.boundingBox()
//                let width = Double(box.maxX - box.minX)
//                let height = Double(box.maxY - box.minY)
//
//                return width >= 4 && height >= 4
//            }
            // TODO: Add min width/height rather than just size
            .assign(to: &$currentCluster)
            
        return $currentCluster
            .compactMap { $0 }
            .removeDuplicates()
            .pairwise()
            .parseDelta("", top: topName, bottom: bottomName)
            .filter { $0.hasAction }
            .eraseToAnyPublisher()
    
    }
    
    
}

