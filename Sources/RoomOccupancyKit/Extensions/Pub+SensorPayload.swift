//
//  Pub+SensorPayload.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/19/21.
//

import Foundation
import OpenCombineShim

extension Publisher where Output == SensorPayload, Failure == Never {
    
    func logSensorData() -> AnyPublisher<SensorPayload, Never> {
        self.map { data -> SensorPayload in
            data.logData()
            return data
        }
        .eraseToAnyPublisher()
    }
    
    func averageFrames(_ count: Int) -> AnyPublisher<SensorPayload, Never> {
        // Average a number of frames together to make the values more stable
        self.collect(count)
            .map { buffer -> SensorPayload in
                
                // Determine the longest data set
                let maxLength = buffer.reduce(0) { length, data in
                    Swift.max(length, data.pixels.count)
                }
                
                // Create an empty array with the length from the first element
                let emptyArray = Array(repeating: Double.zero, count: maxLength)
                
                let totals: [Double] = buffer.reduce(emptyArray) { pixelTotal, payload in
                    // Add all the values together
                    return pixelTotal.enumerated().map { index, value in
                        value + payload.rawData[index]
                    }
                }
                
                // Average the values with the frame buffer
                let averageData = totals.map { $0 / Double(count) }
                
                // Return the first elemet with the new data
                return SensorPayload(sensor: buffer[0].sensor,
                                     rows: buffer[0].rows,
                                     cols: buffer[0].cols,
                                     data: averageData)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Publisher where Output == SensorPayload?, Failure == Never {
    func logSensorData() -> AnyPublisher<SensorPayload?, Never> {
        self.map { data -> SensorPayload? in
            if let data = data {
                data.logData()
            }
            return data
        }
        .eraseToAnyPublisher()
    }
    

}


