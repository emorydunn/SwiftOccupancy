//
//  TestData.swift
//  ThermalViewerTests
//
//  Created by Emory Dunn on 5/19/21.
//

import Foundation
@testable import RoomOccupancyKit
import AMG88


enum MockData: String {
    
    /// Sensor data of someone walking from the bottom of the sensor to the top and then back.
    case twoPassWalk = "two-pass-walk"
    
    var data: [SensorPayload] {
        guard let file = Bundle.module.url(forResource: rawValue, withExtension: "json") else {
            preconditionFailure("'\(rawValue).json' does not exist in \(Bundle.module.resourcePath!)")
        }
        do {
            let contents = try Data(contentsOf: file)
            return try JSONDecoder().decode([SensorPayload].self, from: contents)
        } catch {
            preconditionFailure(error.localizedDescription)
        }
    }
}

class MockSensor: AMG88Protocol {
    
    var currentIndex = 0
    var emptyOnLoop: Bool
    
    let testData: [SensorPayload]
    
    init(emptyOnLoop: Bool, data: MockData = .twoPassWalk) {
        self.emptyOnLoop = emptyOnLoop
        self.testData = data.data
    }
    
    func readPixels() -> [Float] {
        if currentIndex == testData.count {
            if emptyOnLoop {
                NSLog("Returning Empty Data")
                return []
            }
            
            currentIndex = 0
            NSLog("Resetting Test Data Count")
        }
        
        let data = testData[currentIndex].rawData
        
        currentIndex += 1
        
        return data
    }
    
    func readThermistor() -> Float {
        Float.random(in: 20..<30)
    }
    
    func setInterruptLevels(high: Float, low: Float, hysteresis: Float) {
        fatalError("No-op in mock interface")
    }
    
    func getInterrupts() -> [[Bool]] {
        fatalError("No-op in mock interface")
    }
    
    func clearInterrupt() {
        fatalError("No-op in mock interface")
    }
    
    func enableInterrupt() {
        fatalError("No-op in mock interface")
    }
    
    func disableInterrupt() {
        fatalError("No-op in mock interface")
    }
    
    func enableMovingAverage() {
        fatalError("No-op in mock interface")
    }
    
    func disableMovingAverage() {
        fatalError("No-op in mock interface")
    }
   
}
