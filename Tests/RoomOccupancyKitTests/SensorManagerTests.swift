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
    
    func testOccupancy() async throws {
        let sensor = I2CAMGSensor(sensor: MockSensor(emptyOnLoop: true))
        
        let counter = OccupancyCounter(sensor: sensor)
        counter.bottomRoomCount = 1
        
        do {
            for try await data in sensor.data {
                try counter.countChanges(using: data)
            }
        } catch {
            XCTAssertEqual(counter.topRoomCount, 0)
            XCTAssertEqual(counter.bottomRoomCount, 1)
        }

    }
    
}
