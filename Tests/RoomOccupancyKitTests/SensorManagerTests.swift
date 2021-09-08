//
//  SensorManagerTests.swift
//  
//
//  Created by Emory Dunn on 5/25/21.
//

import Foundation
import XCTest
import OpenCombineShim
@testable import RoomOccupancyKit

class SensorManagerTests: XCTestCase {
    
    var tokens: [AnyCancellable] = []
    
    func testMQTT() {
        let manager = SensorManager(sensors: [], broker: HAMQTTConfig(username: nil, password: nil), haConfig: nil)
        
        manager.sensors = [
            MQTTSensor("office-hall", topName: .room("Hall"), bottomName: .room("Office")),
            MQTTSensor("bedroom-hall", topName: .room("Hall"), bottomName: .room("Bedroom")),
        ]
        
        let exp = expectation(description: "MQTT")
        
        manager.monitorMQTT()
        
//        manager.$occupancy.sink { newValue in
//            print(newValue)
////            exp.fulfill()
//        }
//        .store(in: &tokens)
        
        waitForExpectations(timeout: 120)
    }
}
