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
import AMG88

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

    @Option(help: "The hysteresis value")
    var hysteresis: Float = 5

    func run() throws {
//        let sensor = I2CAMGSensor(board: board)
        let sensor = AMG88(SwiftyGPIO.hardwareI2Cs(for: board)![1])
        
        let intPin = SwiftyGPIO.GPIOs(for: board)[.P26]!
        intPin.direction = .IN
        
        intPin.onChange { _ in
            self.printInterrupts(with: sensor)
        }

        sensor.lowInterrupt = low
        sensor.highInterrupt = high
        sensor.hysteresis = hysteresis
        
        sensor.interruptMode = .absolute
        sensor.interruptEnabled = .enabled
        
        print(sensor.lowInterrupt, sensor.highInterrupt, sensor.hysteresis)

        print("Putting the main thread into a run loop")
        RunLoop.main.run()
    }
    
    func printInterrupts(with sensor: AMG88) {
        print(Date())
        let ints = sensor.getInterrupts()
        
        ints.forEach { row in
            row.forEach {
                print($0 ? "1" : "0", terminator: " ")
            }
            print()
        }
    }
}

