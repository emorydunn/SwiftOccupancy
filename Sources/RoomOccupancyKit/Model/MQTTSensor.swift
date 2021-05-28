//
//  File.swift
//  
//
//  Created by Emory Dunn on 5/25/21.
//

import Foundation
import OpenCombineShim
import MQTT

public class MQTTSensor: ObservableObject, Decodable, Identifiable {
    
    public enum CodingKeys: String, CodingKey {
        case name, topName, bottomName
    }
    
    @available(*, renamed: "name")
    public var sensorName: String { name }
    
    public let name: String
    
    public var id: String { name }
    
    public let topName: Room
    public let bottomName: Room
    
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
    
    func parseData(from packets: AnyPublisher<PublishPacket, Error>, assigningTo published: inout Published<OccupancyChange>.Publisher) {
        self.monitorData(from: packets).assign(to: &published)
    }
    
    
    func monitorData(from packets: AnyPublisher<PublishPacket, Error>) -> AnyPublisher<OccupancyChange, Never> {
        
        packets
            // Filter packets for this sensor
            .filter { packet in
                packet.topic.hasSuffix(self.sensorName)
            }
            // Map to SensorPayload
            .map { packet in
                SensorPayload(sensor: self.sensorName, data: packet.payload)
            }
            .breakpointOnError()
            .replaceError(with: nil)
//            .logSensorData()
            .assign(to: &$sensorData)

        // Collect rolling average temp
        $sensorData
            .compactMap { $0 }
            .compactMap { $0.mean }
            .collect(100)
            .map { temps in
                (temps.reduce(0, +) / Double(temps.count)).rounded()
            }
            .print("Average Temp")
            .assign(to: &$averageTemp)
            
        // Process Clusters
        $sensorData
            .compactMap { $0 }
            .averageFrames(2)
            .findRelevantPixels(averageTemperature: averageTemp, deltaThreshold: 2)
//            .logGrid()
            .clusterPixels()
            .map { $0.largest(minSize: 10) } // Map the clusters to the largest
            .assign(to: &$currentCluster)
            
        return $currentCluster
            .compactMap { $0 }
//            .logGrid()
            .removeDuplicates()
            .pairwise()
//            .print("Clusters")
            .parseDelta("", top: topName, bottom: bottomName)
            .filter { $0.hasAction }
            .print("New delta")
            .eraseToAnyPublisher()
    
    }
    
    
}

