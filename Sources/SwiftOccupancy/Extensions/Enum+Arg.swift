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

public enum SensorSource: String, ExpressibleByArgument {
    case mqtt
    
    case RaspberryPiRev1   // Pi A,B Revision 1
    case RaspberryPiRev2   // Pi A,B Revision 2
    case RaspberryPiPlusZero // Pi A+,B+,Zero with 40 pin header
    case RaspberryPiZero2  // Pi Zero 2, derived from Pi3
    case RaspberryPi2 // Pi 2 with 40 pin header
    case RaspberryPi3 // Pi 3 with 40 pin header
    case RaspberryPi4 // Pi 4 with 40 pin header
    case CHIP
    case BeagleBoneBlack
    case OrangePi
    case OrangePiZero

}

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

extension URL: ExpressibleByArgument {
    public init?(argument: String) {
        self = URL(fileURLWithPath: argument,
            relativeTo: Process().executableURL)
    }
}

struct Directory: ExpressibleByArgument {
    
    let url: URL
    
    public init?(argument: String) {
        self.url = URL(
            fileURLWithPath: argument,
            relativeTo: Process().executableURL)
        
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        
        var isDir: ObjCBool = false
        _ = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)

        if isDir.boolValue == false { return nil }

    }
}

enum SensorAddress: String, ExpressibleByArgument, CaseIterable {
    case address68 = "68"
    case address69 = "69"

    var address: Int {
        switch self {
        case .address68:
            return 0x68
        case .address69:
            return 0x69
        }
    }
}
