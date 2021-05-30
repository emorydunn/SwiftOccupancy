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
    
    func mapToChange(using sensors: [MQTTSensor]) -> AnyPublisher<OccupancyChange, Never> {
        return Publishers.MergeMany(sensors.map { sensor -> AnyPublisher<OccupancyChange, Never> in
            return sensor.monitorData(from: self.eraseToAnyPublisher())
        })
            .eraseToAnyPublisher()
    }
    
}

