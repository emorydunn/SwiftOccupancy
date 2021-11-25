//
//  File.swift
//  
//
//  Created by Emory Dunn on 11/24/21.
//

import XCTest
@testable import RoomOccupancyKit

class TempDrawingTests: XCTestCase {
    
    func testNormalize() {
        let temp: Float = 21
        
        let norm = temp.normalize(16, 30)
        
        XCTAssertEqual(norm, 0.3571428671)
    }
    
    func testNormalizeOutOfRange() {
        let temp: Float = 35
        
        let norm = temp.normalize(16, 30, extend: true)
        
        XCTAssertEqual(norm, 1)
    }
    
    
    func testNormalizeOutOfRange_Overflow() {
        let temp: Float = 35
        
        let norm = temp.normalize(16, 30, extend: false)
        
        XCTAssertEqual(norm, 1.3571428571)
    }
    
    func testDraw() throws {
        let data = MockSensor(emptyOnLoop: false).testData.randomElement()!
        let payload = try SensorPayload(data: data, thermistorTemperature: 21)
        
        
        let image = try payload.drawImage(cluster: nil)
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(#function).appendingPathExtension("png")
        image.writePNG(atPath: tempDir.path)
        
        print(tempDir.path)
    }
    
}
