//
//  File.swift
//  
//
//  Created by Emory Dunn on 12/31/21.
//

import Foundation
import ArgumentParser
import SwiftyGPIO
import RoomOccupancyKit

struct InterruptCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "interrupt",
                                                    abstract: "Log interrupt events.",
                                                    discussion: "Data is read from an I2C sensor and logged to stdout or saved to disk.",
                                                    version: "0.1.",
                                                    shouldDisplay: true)
    
    @Option(help: "The board for connecting via I2C")
    var board: SupportedBoard = SupportedBoard.RaspberryPi4
    
    @Option(help: "The low temp")
    var low: Float = 16
    
    @Option(help: "The low temp")
    var high: Float = 25

    

    func run() throws {
        let sensor = I2CAMGSensor(board: board)
        
        let intPin = SwiftyGPIO.GPIOs(for: board)[.P26]!
        intPin.direction = .IN
        
        intPin.onChange { _ in
            self.printInterrupts(with: sensor)
        }

        sensor.sensor.setInterruptLevels(high: high, low: low, hysteresis: 0.95)
        
        sensor.sensor.enableInterrupt()
        
        printInterrupts(with: sensor)
        
        print("Putting the main thread into a run loop")
        RunLoop.main.run()
    }
    
    func printInterrupts(with sensor: I2CAMGSensor) {
        print(Date())
        let ints = sensor.sensor.getInterrupts()
        
        ints.forEach { row in
            row.forEach {
                print($0 ? "1" : "0")
            }
        }
    }
}

