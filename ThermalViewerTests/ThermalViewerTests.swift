//
//  ThermalViewerTests.swift
//  ThermalViewerTests
//
//  Created by Emory Dunn on 5/16/21.
//

import XCTest
@testable import ThermalViewer

class ClusterTests: XCTestCase {
    
    let sensor = Sensor(URL(string: "localhost")!)

    func testBoundingBox() {
        let payload = SensorPayload(sensor: "AMG8833", data: "24.00,25.25,25.75,26.75,25.00,27.75,27.50,27.25,22.50,23.25,24.75,25.00,25.00,27.75,27.25,27.00,22.00,21.75,22.50,23.25,25.50,27.75,27.25,27.00,21.75,21.75,22.00,22.25,24.25,27.50,27.50,27.00,21.25,21.25,22.50,23.25,24.25,25.50,26.50,26.75,21.50,21.75,22.25,23.50,23.25,22.50,26.00,27.00,22.75,21.50,23.25,23.50,21.50,21.75,23.25,25.50,22.00,24.00,24.25,22.00,21.75,21.50,21.25,22.25")
        
        let cluster = sensor.clusterPixels(payload).largest()!
        
        let box = cluster.boundingBox()
        
        XCTAssertEqual(box.minX, 6)
        XCTAssertEqual(box.minY, 1)
        XCTAssertEqual(box.maxX, 8)
        XCTAssertEqual(box.maxY, 6)

    }
    
    func testCenter() {
        let payload = SensorPayload(sensor: "AMG8833", data: "20.75,20.75,21.25,21.5,21.0,23.25,22.0,22.0,21.0,21.75,22.0,22.75,22.75,23.75,22.0,22.25,21.25,21.75,24.75,26.5,26.75,26.25,23.5,23.0,21.0,22.25,25.75,26.25,26.25,25.75,23.75,22.75,21.75,23.75,26.25,26.5,25.75,26.25,24.0,22.0,21.75,21.75,25.25,25.75,25.75,27.25,24.0,23.25,20.75,21.25,22.0,23.25,23.0,22.5,22.5,23.75,20.75,20.75,20.5,21.75,21.0,22.0,21.0,22.5")
        
        let cluster = sensor.clusterPixels(payload).largest()!
        
//        let box = cluster.boundingBox()
        let center = cluster.center()
        
        
//        print(box.maxX - box.minX)
//        print(box.maxY - box.minY)
        
//        XCTAssertEqual(center?.x, 7)
//        XCTAssertEqual(center?.y, 4)
//        XCTAssertEqual(box.maxX, 7)
//        XCTAssertEqual(box.maxY, 5)
        
    }

}
