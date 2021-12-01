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
        XCTAssertEqual((30.0 as Float).normalize(15, 30), 1)
        XCTAssertEqual((10.0 as Float).normalize(15, 30), 0)
    }
    
    
    func testDraw() throws {
        let data = MockSensor(emptyOnLoop: false).testData.randomElement()!

        XCTAssertNoThrow(try data.drawImage(cluster: nil))
//        let image = try payload.drawImage(cluster: nil)
        
//        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(#function).appendingPathExtension("png")
//        image.writePNG(atPath: tempDir.path)
//
//        print(tempDir.path)
    }
    
}
