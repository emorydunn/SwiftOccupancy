//
//  RoomTests.swift
//  
//
//  Created by Emory Dunn on 5/24/21.
//

import XCTest
@testable import RoomOccupancyKit

class RoomTests: XCTestCase {
    
    func testSlug() {
        XCTAssertEqual(Room.room("Room with Spaces").slug, "room_with_spaces")
        XCTAssertEqual(Room.æther.slug, "æther")
    }
}
        
