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
        
        let occupancy = OccupancyCounter(sensor: sensor)
        
//        do {
//            try await occupancy.updateChanges()
//        } catch {
//            
//        }
//        
//        print(occupancy.topRoomCount, occupancy.bottomRoomCount)
    }
    
}
