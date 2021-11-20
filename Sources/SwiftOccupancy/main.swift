//
//  main.swift
//  
//
//  Created by Emory Dunn on 5/20/21.
//

import Foundation
import RoomOccupancyKit

// Default to the Home Assistant add-on config
var configFile: URL = URL(fileURLWithPath: "/data/options.json")

// If the user specified a config, use that instead
if CommandLine.arguments.count == 2 {
    configFile = URL(fileURLWithPath: CommandLine.arguments[1])
}

// Parse the file
let data: Data
do {
    data = try Data(contentsOf: configFile)
} catch {
    print("There was a problem reading \(configFile.path).")
    print(error.localizedDescription)
    exit(1)
}

do {
    let manager = try JSONDecoder().decode(PiSensorManager.self, from: data)
    manager.begin()
} catch {
    print("There was a problem decoding the config file.")
    print(error)
    exit(1)
}
