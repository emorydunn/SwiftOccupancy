//
//  File.swift
//  
//
//  Created by Emory Dunn on 5/25/21.
//

import Foundation
import OpenCombineShim
import MQTT

public class MQTTSensor: Decodable {
    
    public enum CodingKeys: String, CodingKey {
        case sensorName, topName, bottomName
    }
    
    public let sensorName: String
    
    public let topName: Room
    public let bottomName: Room
    
//    public var sensorData: PassthroughSubject<PublishPacket, Error> = PassthroughSubject()
//    @Published public var deltas: OccupancyChange = OccupancyChange.default
    
//    @Published public var currentData: SensorPayload = SensorPayload(sensor: "Fake Sensor", data: [])
//    @Published public var currentCluster: Cluster?
//    @Published public var currentDelta: OccupancyChange = OccupancyChange.default
    public var averageTemp: Double = 27.0 //CurrentValueSubject<Double, Never>(21)
    
    var tokens: [AnyCancellable] = []
    
    public init(sensorName: String, topName: Room, bottomName: Room) {
        self.sensorName = sensorName
        self.topName = topName
        self.bottomName = bottomName

    }
    
    func parseData(from packets: AnyPublisher<PublishPacket, Error>, assigningTo published: inout Published<OccupancyChange>.Publisher) {
        self.monitorData(from: packets).assign(to: &published)
    }
    
    
    func monitorData(from packets: AnyPublisher<PublishPacket, Error>) -> AnyPublisher<OccupancyChange, Never> {
        
        let sensorData = packets
            // Filter packets for this sensor
            .filter { packet in
                packet.topic.hasSuffix(self.sensorName)
            }
            // Map to SensorPayload
            .map { packet in
                SensorPayload(sensor: self.sensorName, data: packet.payload)
            }
//            .print("\(sensorName) Payload")
            .breakpointOnError()
            .replaceError(with: nil)
//            .catch { error -> SensorPayload? in
//                print(error)
//                return Just(nil)
//            }
            .compactMap { $0 }
            .share()
        
//        sensorData.assign(to: &$currentData)
            
        // Collect rolling average temp
        sensorData
            .compactMap { $0.mean }
            .collect(100)
            .map { temps in
                (temps.reduce(0, +) / Double(temps.count)).rounded()
            }
            .print("Average Temp")
            .assign(to: \.averageTemp, on: self)
            .store(in: &tokens)
//            .assign(to: &$averageTemp)
            
        // Process Clusters
        return sensorData
            .averageFrames(2)
            .findRelevantPixels(averageTemperature: averageTemp, deltaThreshold: 2)
//            .logGrid()
//            .print("Pixels")
            .clusterPixels()
//            .print("Clusters")
            .map { $0.largest(minSize: 10) } // Map the clusters to the largest
            .compactMap { $0 }
            .removeDuplicates()
            .logGrid()
//            .print("Largest Cluster")
            .pairwise()
            .print("Clusters")
            .parseDelta("", top: topName, bottom: bottomName)
            .filter { $0.hasAction }
            .print("New delta")
            .eraseToAnyPublisher()
    
    }
    
    
}

