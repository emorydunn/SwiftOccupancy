//
//  ThermalViewerTests.swift
//  ThermalViewerTests
//
//  Created by Emory Dunn on 5/16/21.
//

import XCTest
import Combine
@testable import RoomOccupancyKit

class ClusterTests: XCTestCase {
    
//    let sensor = Sensor(URL(string: "localhost")!)
    
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        cancellables = []
    }
    
    func testPlayback() {
        
        let mockSensor = MockSensor()
        
        let senseExp = expectation(description: "Sensor Reading")
        
//        mockSensor.$currentDelta
//            .sink(receiveCompletion: { completion in
//                senseExp.fulfill()
//            }, receiveValue: { change in
//                print(change)
//            })
//            .store(in: &cancellables)
//
//        mockSensor.$currentCluster
//            .sink { cluster in
//                cluster?.printGrid()
//            }
//            .store(in: &cancellables)
//
//        mockSensor.monitorData()
//
//        waitForExpectations(timeout: 10, handler: nil)
        
        //        twoPassData.enumerated().forEach { index, data in
        //            let pixels = sensor.findRelevantPixels(data)
        //
        //            print("Frame \(index)")
        //            if let cluster = sensor.clusterPixels(data).filter({ $0.size >= sensor.minClusterSize }).largest() {
        //                cluster.printGrid()
        //            } else {
        //                pixels.printGrid()
        //            }
        //        }
    }
    
    func testFindPixels() {
        let payload = SensorPayload(sensor: "AMG8833", data: "21.020.021.021.021.021.521.022.019.520.020.019.520.020.020.521.019.520.020.021.520.020.020.521.020.020.021.022.521.520.521.021.520.021.024.025.026.023.021.021.520.521.026.026.026.526.023.022.021.020.025.026.526.026.022.521.520.020.021.022.023.022.521.021.0")!
        Just(payload.pixels)
            .findRelevantPixels(averageTemperature: 21, deltaThreshold: 2)
            .sink { pixels in
                pixels.printGrid()
                XCTAssertEqual(pixels.count, 17)
            }
            .store(in: &cancellables)
 
    }
    
    func testClustering() {
        let payload = SensorPayload(sensor: "AMG8833", data: "22.021.022.024.021.022.023.024.020.022.026.026.025.021.021.023.021.024.026.025.025.023.021.022.022.025.027.026.025.024.022.022.020.020.022.024.023.020.021.021.021.020.021.020.021.020.021.021.019.020.020.020.020.020.021.021.020.020.021.020.020.020.020.021.0")!
        Just(payload.pixels)
            .findRelevantPixels(averageTemperature: 21, deltaThreshold: 2)
            .clusterHotestPixels()
            .sink { cluster in
                cluster?.printGrid()
                XCTAssertNotNil(cluster)
                
                XCTAssertEqual(cluster?.center.x, 4)
                XCTAssertEqual(cluster?.center.y, 3)
            }
            .store(in: &cancellables)

    }
    
    func testClustering_EdgeOfFrame() {
        let payload = SensorPayload(sensor: "AMG8833", data: [20.0,21.0,24.333333333333332,25.0,24.666666666666668,24.333333333333332,23.0,22.0,20.666666666666668,22.333333333333332,24.0,25.0,25.0,23.0,22.333333333333332,21.0,21.0,25.0,24.0,24.0,24.666666666666668,24.333333333333332,21.0,20.0,21.0,23.333333333333332,24.0,24.0,26.0,26.0,22.0,20.0,21.666666666666668,20.666666666666668,20.666666666666668,21.0,22.0,21.666666666666668,20.0,20.666666666666668,20.0,20.0,20.0,20.0,20.0,20.0,19.666666666666668,20.0,19.0,19.666666666666668,19.333333333333332,19.666666666666668,20.0,19.666666666666668,20.0,19.666666666666668,19.666666666666668,20.0,19.666666666666668,19.666666666666668,20.0,19.333333333333332,19.0,19.666666666666668])!
        Just(payload.pixels)
            .findRelevantPixels(averageTemperature: 21, deltaThreshold: 2)
            .clusterHotestPixels()
            .sink { cluster in
                cluster?.printGrid()
                XCTAssertNotNil(cluster)
                
                XCTAssertEqual(cluster?.center.x, 5)
                XCTAssertEqual(cluster?.center.y, 3)
            }
            .store(in: &cancellables)

    }
    
    
    
    func testBoundingBox() {
        let payload = SensorPayload(sensor: "AMG8833", data: "21.020.021.021.021.021.521.022.019.520.020.019.520.020.020.521.019.520.020.021.520.020.020.521.020.020.021.022.521.520.521.021.520.021.024.025.026.023.021.021.520.521.026.026.026.526.023.022.021.020.025.026.526.026.022.521.520.020.021.022.023.022.521.021.0")!
        Just(payload.pixels)
            .findRelevantPixels(averageTemperature: 21, deltaThreshold: 2)
            .clusterHotestPixels()
            .compactMap { $0 }
            .sink { cluster in
                let bb = cluster.boundingBox()
                
                XCTAssertEqual(bb.maxX, 7)
                XCTAssertEqual(bb.maxY, 8)
                XCTAssertEqual(bb.minX, 3)
                XCTAssertEqual(bb.minY, 4)

            }
            .store(in: &cancellables)
        
    }
    
    func testCenter() {
        let payload = SensorPayload(sensor: "AMG8833", data: "21.020.021.021.021.021.521.022.019.520.020.019.520.020.020.521.019.520.020.021.520.020.020.521.020.020.021.022.521.520.521.021.520.021.024.025.026.023.021.021.520.521.026.026.026.526.023.022.021.020.025.026.526.026.022.521.520.020.021.022.023.022.521.021.0")!
        Just(payload.pixels)
            .findRelevantPixels(averageTemperature: 21, deltaThreshold: 2)
            .clusterHotestPixels()
            .compactMap { $0 }
            .sink { cluster in
                XCTAssertEqual(cluster.center.x, 5)
                XCTAssertEqual(cluster.center.y, 6)
                
            }
            .store(in: &cancellables)
        
        
    }
    
}
