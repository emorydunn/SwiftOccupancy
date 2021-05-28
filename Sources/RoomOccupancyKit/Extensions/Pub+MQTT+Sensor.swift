//
//  File.swift
//  
//
//  Created by Emory Dunn on 5/25/21.
//

import Foundation
import OpenCombineShim
import MQTT

extension Publisher where Output == PublishPacket, Failure == Error {
    
//    func mapToPayload(topicPrefix: String, rows: Int = 8, columns: Int = 8) -> AnyPublisher<SensorPayload, Failure> {
//        self.map { packet in
//            
//            let sensor = packet.topic.replacingOccurrences(of: topicPrefix, with: "")
//            return SensorPayload(sensor: sensor, rows: rows, cols: columns, data: packet.payload)
//            
//        }
//        .eraseToAnyPublisher()
//        
//    }
//    
    func mapToChange(using sensors: [MQTTSensor]) -> AnyPublisher<OccupancyChange, Never> {
        return Publishers.MergeMany(sensors.map { $0.monitorData(from: self.eraseToAnyPublisher()) })
            .eraseToAnyPublisher()
    }
}

