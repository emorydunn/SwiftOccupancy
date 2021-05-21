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
let data = try Data(contentsOf: configFile)
let manager = try JSONDecoder().decode(SensorManager.self, from: data)

// Begin monitoring the sensors
manager.monitorSensors()
RunLoop.main.run()
