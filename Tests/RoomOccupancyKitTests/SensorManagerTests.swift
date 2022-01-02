//
//  SensorManagerTests.swift
//  
//
//  Created by Emory Dunn on 5/25/21.
//

import Foundation
import XCTest
@testable import RoomOccupancyKit

class OccupancyCounterTests: XCTestCase {
    
    func testOccupancy_twoPassDoorEdge() throws {
        
//        let sensor = I2CAMGSensor(sensor: MockSensor(emptyOnLoop: true))
        let data = MockData.twoPassDoorEdge.orderedData
        let counter = OccupancyCounter(topRoom: .room("Top"), bottomRoom: .room("Bottom"))
//
//        try counter.countChanges(using: data[85])
//        try counter.countChanges(using: data[86])
//        try counter.countChanges(using: data[87])
//        try counter.countChanges(using: data[88])
        
//        print(counter.topRoom, counter.topRoomCount)
//        print(counter.bottomRoom, counter.bottomRoomCount)
        
        try counter.countChanges(using: data)
        
        XCTAssertEqual(counter.topRoomCount, 1)
        XCTAssertEqual(counter.bottomRoomCount, 0)

    }
    
}
