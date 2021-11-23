//
//  ThermalViewerTests.swift
//  ThermalViewerTests
//
//  Created by Emory Dunn on 5/16/21.
//

import XCTest
@testable import RoomOccupancyKit

class ClusterTests: XCTestCase {
    
    func testFindPixels() {
        let payload = try! SensorPayload(data: [21.0, 20.0, 21.0, 21.0, 21.0, 21.5, 21.0, 22.0,
                                                19.5, 20.0, 20.0, 19.5, 20.0, 20.0, 20.5, 21.0,
                                                19.5, 20.0, 20.0, 21.5, 20.0, 20.0, 20.5, 21.0,
                                                20.0, 20.0, 21.0, 22.5, 21.5, 20.5, 21.0, 21.5,
                                                20.0, 21.0, 24.0, 25.0, 26.0, 23.0, 21.0, 21.5,
                                                20.5, 21.0, 26.0, 26.0, 26.5, 26.0, 23.0, 22.0,
                                                21.0, 20.0, 25.0, 26.5, 26.0, 26.0, 22.5, 21.5,
                                                20.0, 20.0, 21.0, 22.0, 23.0, 22.5, 21.0, 21.0],
                                         thermistorTemperature: 21)
        
        let cluster = Cluster(from: payload, deltaThreshold: 2)
        
        cluster.printGrid()
        
        XCTAssertEqual(cluster.size, 11)

    }
    
    func testClustering() {
        let payload = try! SensorPayload(data: [22.0, 21.0, 22.0, 24.0, 21.0, 22.0, 23.0, 24.0,
                                                20.0, 22.0, 26.0, 26.0, 25.0, 21.0, 21.0, 23.0,
                                                21.0, 24.0, 26.0, 25.0, 25.0, 23.0, 21.0, 22.0,
                                                22.0, 25.0, 27.0, 26.0, 25.0, 24.0, 22.0, 22.0,
                                                20.0, 20.0, 22.0, 24.0, 23.0, 20.0, 21.0, 21.0,
                                                21.0, 20.0, 21.0, 20.0, 21.0, 20.0, 21.0, 21.0,
                                                19.0, 20.0, 20.0, 20.0, 20.0, 20.0, 21.0, 21.0,
                                                20.0, 20.0, 21.0, 20.0, 20.0, 20.0, 20.0, 21.0],
                                         thermistorTemperature: 21)
        
        let cluster = Cluster(from: payload, deltaThreshold: 2)
        
        cluster.printGrid()
        
        XCTAssertEqual(cluster.center.x, 4)
        XCTAssertEqual(cluster.center.y, 3)
        
    }
    
    func testClustering_EdgeOfFrame() {
        let payload = try! SensorPayload(data: [20, 21, 24, 25, 24, 24, 23, 22,
                                                20, 22, 24, 25, 25, 23, 22, 21,
                                                21, 25, 24, 24, 24, 24, 21, 20,
                                                21, 23, 24, 24, 26, 26, 22, 20,
                                                21, 20, 20, 21, 22, 21, 20, 20,
                                                20, 20, 20, 20, 20, 20, 19, 20,
                                                19, 19, 19, 19, 20, 19, 20, 19,
                                                19, 20, 19, 19, 20, 19, 19, 19],
                                         thermistorTemperature: 21)
        
        let cluster = Cluster(from: payload, deltaThreshold: 2)
        
        cluster.printGrid()
        
        XCTAssertEqual(cluster.center.x, 4)
        XCTAssertEqual(cluster.center.y, 3)

    }
    
    
    
    func testBoundingBox() {
        let payload = try! SensorPayload(data: [22.0, 21.0, 22.0, 24.0, 21.0, 22.0, 23.0, 24.0,
                                                20.0, 22.0, 26.0, 26.0, 25.0, 21.0, 21.0, 23.0,
                                                21.0, 24.0, 26.0, 25.0, 25.0, 23.0, 21.0, 22.0,
                                                22.0, 25.0, 27.0, 26.0, 25.0, 24.0, 22.0, 22.0,
                                                20.0, 20.0, 22.0, 24.0, 23.0, 20.0, 21.0, 21.0,
                                                21.0, 20.0, 21.0, 20.0, 21.0, 20.0, 21.0, 21.0,
                                                19.0, 20.0, 20.0, 20.0, 20.0, 20.0, 21.0, 21.0,
                                                20.0, 20.0, 21.0, 20.0, 20.0, 20.0, 20.0, 21.0],
                                         thermistorTemperature: 21)
        
        let cluster = Cluster(from: payload, deltaThreshold: 2)
        
        cluster.printGrid()
        
        let bb = cluster.boundingBox
        
        XCTAssertEqual(bb.minX, 2)
        XCTAssertEqual(bb.minY, 1)
        
        XCTAssertEqual(bb.maxX, 6)
        XCTAssertEqual(bb.maxY, 5)
        
        
    }
    
    func testCenter() {
        let payload = try! SensorPayload(data: [22.0, 21.0, 22.0, 24.0, 21.0, 22.0, 23.0, 24.0,
                                                20.0, 22.0, 26.0, 26.0, 25.0, 21.0, 21.0, 23.0,
                                                21.0, 24.0, 26.0, 25.0, 25.0, 23.0, 21.0, 22.0,
                                                22.0, 25.0, 27.0, 26.0, 25.0, 24.0, 22.0, 22.0,
                                                20.0, 20.0, 22.0, 24.0, 23.0, 20.0, 21.0, 21.0,
                                                21.0, 20.0, 21.0, 20.0, 21.0, 20.0, 21.0, 21.0,
                                                19.0, 20.0, 20.0, 20.0, 20.0, 20.0, 21.0, 21.0,
                                                20.0, 20.0, 21.0, 20.0, 20.0, 20.0, 20.0, 21.0],
                                         thermistorTemperature: 21)
        
        let cluster = Cluster(from: payload, deltaThreshold: 2)
        
        cluster.printGrid()
        
        XCTAssertEqual(cluster.center.x, 4)
        XCTAssertEqual(cluster.center.y, 3)

        
    }
    
}
