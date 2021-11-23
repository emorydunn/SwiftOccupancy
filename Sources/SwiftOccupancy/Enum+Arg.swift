//
//  File.swift
//  
//
//  Created by Emory Dunn on 11/23/21.
//

import Foundation
import ArgumentParser
import RoomOccupancyKit
import SwiftyGPIO

extension SupportedBoard: ExpressibleByArgument { }

extension Room: ExpressibleByArgument {
    public init?(argument: String) {
        switch argument {
        case "", "aether", "æther":
            self = Room.æther
        default:
            self = .room(argument)
        }
    }
}
