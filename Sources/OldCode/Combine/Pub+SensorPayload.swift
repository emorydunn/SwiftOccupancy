//
//  Pub+SensorPayload.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/19/21.
//

import Foundation
import OpenCombine

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

extension OpenCombine.Publisher where Output == [Pixel], Failure == Never {
    
    func findRelevantPixels(averageTemperature: Float, deltaThreshold: Float) -> AnyPublisher<Output, Failure> {
        let threshold = averageTemperature + deltaThreshold
        
        return self.map { pixels in
            pixels.filter { $0.temp >= threshold }
        }
        .eraseToAnyPublisher()
    }
    
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
    
    public func clusterHottestPixels() -> AnyPublisher<Cluster?, Never> {
        
        // Start with the hottest pixel
        self.map { pixels in
            
//            Cluster(from: pixels, deltaThreshold: 2)
//
//            let hottestPixel = pixels.reduce(into: Pixel(x: 0, y: 0, temp: 0)) { currentHottest, pixel in
//                currentHottest = pixel.temp > currentHottest.temp ? pixel : currentHottest
//            }
//
//            let cluster = Cluster(hottestPixel)
//            var newPixels: Set<Pixel> = [hottestPixel]
//
//            var keepSearching: Bool = true
//            while keepSearching {
//
//                let oldCount = newPixels.count
//
//                newPixels.forEach { pixel in
//                    // Locate the neighbor pixels
//                    let newNeighbors = pixels.filter {
//
//                        ($0.x == pixel.x - 1 && $0.y == pixel.y) || // Left
//                            ($0.x == pixel.x + 1 && $0.y == pixel.y) || // Right
//                            ($0.x == pixel.x && $0.y - 1 == pixel.y) || // Bottom
//                            ($0.x == pixel.x && $0.y + 1 == pixel.y) // Top
//
//                    }
//
//                    newPixels.formUnion(newNeighbors)
//                }
//
//                keepSearching = newPixels.count != oldCount
//            }
//
//            cluster.pixels.append(contentsOf: newPixels)
            return Cluster(from: pixels)
        }
        .eraseToAnyPublisher()
        
    }
    
}

extension OpenCombine.Publisher where Output == SensorPayload, Failure == Never {
    
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
                let emptyArray = Array(repeating: Float.zero, count: maxLength)
                
                let totals: [Float] = buffer.reduce(emptyArray) { pixelTotal, payload in
                    // Add all the values together
                    return pixelTotal.enumerated().map { index, value in
                        value + payload.rawData[index]
                    }
                }
                
                // Average the values with the frame buffer
                let averageData = totals.map { $0 / Float(count) }
                
                // Return the first element with the new data
                return try! SensorPayload(rows: buffer[0].rows,
                                          cols: buffer[0].cols,
                                          data: averageData,
                                          thermistorTemperature: 0) // FIXME: Average thermistor
            }
            .eraseToAnyPublisher()
    }

    func findRelevantPixels(averageTemperature: Float, deltaThreshold: Float) -> AnyPublisher<[Pixel], Failure> {
        let threshold = averageTemperature + deltaThreshold
        
        return self.map { data in
            data.pixels.filter { $0.temp >= threshold }
        }
        .eraseToAnyPublisher()
    }
    
}

extension OpenCombine.Publisher where Output == SensorPayload?, Failure == Never {
    func logSensorData() -> AnyPublisher<SensorPayload?, Never> {
        self.map { data -> SensorPayload? in
            if let data = data {
                data.logData()
            }
            return data
        }
        .eraseToAnyPublisher()
    }
    

    func averageFrames(_ count: Int) -> AnyPublisher<Output, Failure> {
        // Average a number of frames together to make the values more stable
        self
            .compactMap { $0 }
            .collect(count)
            .map { buffer -> SensorPayload in
                
                // Determine the longest data set
                let maxLength = buffer.reduce(0) { length, data in
                    Swift.max(length, data.pixels.count)
                }
                
                // Create an empty array with the length from the first element
                let emptyArray = Array(repeating: Float.zero, count: maxLength)
                
                let totals: [Float] = buffer.reduce(emptyArray) { pixelTotal, payload in
                    // Add all the values together
                    return pixelTotal.enumerated().map { index, value in
                        value + payload.rawData[index]
                    }
                }
                
                // Average the values with the frame buffer
                let averageData = totals.map { $0 / Float(count) }
                
                // Return the first element with the new data
                return try! SensorPayload(rows: buffer[0].rows,
                                          cols: buffer[0].cols,
                                          data: averageData,
                                          thermistorTemperature: 0) // FIXME: Average thermistor
            }
            .eraseToAnyPublisher()
    }
}


