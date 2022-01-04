//
//  SensorOptions.swift
//  
//
//  Created by Emory Dunn on 1/4/22.
//

import Foundation
import ArgumentParser
import SwiftyGPIO

struct SensorOptions: ParsableArguments {
    
    @Option(help: "The board for connecting via I2C")
    var board: SupportedBoard = SupportedBoard.RaspberryPi4
    
    @Option(help: "The sensor address")
    var address: SensorAddress
}
