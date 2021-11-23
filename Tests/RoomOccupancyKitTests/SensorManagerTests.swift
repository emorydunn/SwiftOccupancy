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
        let sensor = I2CAMGSensor(sensor: MockSensor(emptyOnLoop: false))
        
        let occupancy = OccupancyCounter(sensor: sensor)
        
//        print(occupancy)
        try await occupancy.updateChanges()
//        Task {
//            for try await change in occupancy.countChanges {
//                print("A", change)
//            }
//        }
//
//
//        print("After Task")

    }
    
}
