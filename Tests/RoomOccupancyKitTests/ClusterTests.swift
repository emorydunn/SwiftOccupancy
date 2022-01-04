//
//  ThermalViewerTests.swift
//  ThermalViewerTests
//
//  Created by Emory Dunn on 5/16/21.
//

import Foundation
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
        let payload = try! SensorPayload(data: [17, 16, 16, 17, 17, 18, 18, 18,
                                                17, 17, 17, 17, 17, 18, 18, 18,
                                                18, 17, 17, 17, 18, 20, 19, 18,
                                                17, 17, 17, 16, 20, 23, 20, 20,
                                                16, 17, 16, 16, 18, 22, 20, 19,
                                                17, 16, 16, 16, 16, 16, 17, 18,
                                                16, 16, 16, 15, 16, 16, 16, 16,
                                                16, 16, 15, 15, 15, 15, 15, 15],
                                         thermistorTemperature: 21)
        
        let cluster = Cluster(from: payload, deltaThreshold: 2)

        cluster.printGrid()
        
//        XCTAssertEqual(cluster.center.x, 4)
//        XCTAssertEqual(cluster.center.y, 3)
        
    }
    
    func testClustering_EdgeOfFrame() {
        let payload = MockData.twoPassDoorEdge.orderedData[85]
        
        let cluster = Cluster(from: payload, deltaThreshold: 2)

        cluster.printGrid()
        
        XCTAssertEqual(cluster.center.x, 7)
        XCTAssertEqual(cluster.center.y, 6)

    }
    
    
    
    func testBoundingBox() {
        let payload = MockData.twoPassDoorEdge.orderedData[85]
        
        let cluster = Cluster(from: payload, deltaThreshold: 2)

        cluster.printGrid()
        
        let bb = cluster.boundingBox
        
        XCTAssertEqual(bb.minX, 5)
        XCTAssertEqual(bb.minY, 5)

        XCTAssertEqual(bb.maxX, 8)
        XCTAssertEqual(bb.maxY, 6)
        
        XCTAssertEqual(bb.width, 4)
        XCTAssertEqual(bb.height, 2)
        
        
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
