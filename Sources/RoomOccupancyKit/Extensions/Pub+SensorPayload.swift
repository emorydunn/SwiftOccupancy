//
//  Pub+SensorPayload.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/19/21.
//

import Foundation
import OpenCombineShim

//extension Publisher where Output == [Double], Failure == Never {
//
//    func mapToPixels(rows: Int = 8, columns: Int = 8) {
//        self.compactMap { temps in
//            guard temps.count == rows * columns else { return nil }
//
//            var pixels = [Pixel]()
//        }
//    }
//}

extension Publisher where Output == [Pixel], Failure == Never {
    
    func findRelevantPixels(averageTemperature: Double, deltaThreshold: Double) -> AnyPublisher<Output, Failure> {
        let threshold = averageTemperature + deltaThreshold
        
        return self.map { pixels in
            pixels.filter { $0.temp >= threshold }
        }
        .eraseToAnyPublisher()
    }
    
    public func clusterPixels() -> AnyPublisher<[Cluster], Never> {
        
        self.map { pixels in
            var clusters = [Cluster]()
            
            pixels.forEach { pixel in
                if let neighbor = clusters.first(where: { $0.isNeighbored(to: pixel) }) {
                    neighbor.pixels.append(pixel)
                } else {
                    clusters.append(Cluster(pixel))
                }
            }
    
            return clusters
        }
        
        .eraseToAnyPublisher()
        
    }
    
}

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
                                     data: averageData)!
            }
            .eraseToAnyPublisher()
    }
    
//    func findRelevantPixels(averageTemp: Double, deltaThreshold: Double) {
//        let threshold = averageTemperature + deltaThreshold
//
//        self.map { data in
//            data.pixels
//        }
//    }
    
    func findRelevantPixels(averageTemperature: Double, deltaThreshold: Double) -> AnyPublisher<[Pixel], Failure> {
        let threshold = averageTemperature + deltaThreshold
        
        return self.map { data in
            data.pixels.filter { $0.temp >= threshold }
        }
        .eraseToAnyPublisher()
    }
    
//    func parseDelta(averageTemperature: Double, deltaThreshold: Double) {
//        
//        
//        
//        self
////            .
//            .findRelevantPixels(averageTemperature: averageTemperature, deltaThreshold: deltaThreshold)
//            .clusterPixels()
////            .map { self.clusterPixels($0) }
//            .map { $0.largest(minSize: self.minClusterSize) } // Map the clusters to the largest
//            .compactMap { $0 }
//            .pairwise()
//            .parseDelta("", top: <#T##Room#>, bottom: <#T##Room#>)
////            .pairwise()
////            .p
//    }
    
//    public func clusterPixels() -> AnyPublisher<[Cluster], Never> {
//
//        self.map { pixels in
//            var clusters = [Cluster]()
//
//            pixels.forEach { pixel in
//                if let neighbor = clusters.first(where: { $0.isNeighbored(to: pixel) }) {
//                    neighbor.pixels.append(pixel)
//                } else {
//                    clusters.append(Cluster(pixel))
//                }
//            }
//
//            return clusters
//        }
//
//        .eraseToAnyPublisher()
//
//    }
    
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


