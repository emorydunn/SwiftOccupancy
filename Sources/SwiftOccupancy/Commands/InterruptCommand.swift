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
    
    @OptionGroup var sensorOptions: SensorOptions
    
    @Option(help: "The low temp")
    var low: Float = 16
    
    @Option(help: "The low temp")
    var high: Float = 25

    @Option(help: "The hysteresis value")
    var hysteresis: Float = 5

    func run() throws {
        let sensor = AMG88(SwiftyGPIO.hardwareI2Cs(for: sensorOptions.board)![1], address: sensorOptions.address.address)
        
        let intPin = SwiftyGPIO.GPIOs(for: sensorOptions.board)[.P26]!
        intPin.direction = .IN
        intPin.pull = .up
        
        intPin.onFalling { _ in
            self.printInterrupts(with: sensor)
            sensor.clearInterrupt()
        }

        sensor.lowInterrupt = low
        sensor.highInterrupt = high
        sensor.hysteresis = hysteresis
        
        sensor.setInterruptModeAbsolute()
        sensor.enableInterrupt()
        
        sensor.clearInterrupt()
        
        let interrupt = sensor.interface.readByte(sensor.address, command: 0x03)
        print("Interrupt Mode", String(interrupt, radix: 2))
        print(sensor.lowInterrupt, sensor.highInterrupt, sensor.hysteresis)

        print("Putting the main thread into a run loop")
        
//        while true {
//            if sensor.status.contains(.interruptFlag) {
//                self.printInterrupts(with: sensor)
//                sensor.clearInterrupt()
//            } else {
//                print("waiting for interrupt flag...")
//            }
//
//            sleep(1)
//        }
        
        RunLoop.main.run()

    }
    
    func printInterrupts(with sensor: AMG88) {
        print(Date())
        let ints = sensor.getInterrupts()
        
        ints.forEach { row in
            row.forEach {
                print($0 ? "O" : "•", terminator: "")
            }
            print()
        }
    }
}

