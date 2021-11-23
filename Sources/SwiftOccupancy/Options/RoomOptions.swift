//
//  File.swift
//  
//
//  Created by Emory Dunn on 11/23/21.
//

import Foundation
import ArgumentParser
import RoomOccupancyKit

struct RoomOptions: ParsableArguments {
    @Option(help: "The top room name")
    var topRoom: Room = .æther
    
    @Option(help: "The bottom room name")
    var bottomRoom: Room = .æther
    
    var clientID: String {
        "\(topRoom)-\(bottomRoom)"
    }
}
