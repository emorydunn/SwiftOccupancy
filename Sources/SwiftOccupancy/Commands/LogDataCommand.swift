//
//  File.swift
//  
//
//  Created by Emory Dunn on 11/24/21.
//

import Foundation
import ArgumentParser
import RoomOccupancyKit
import SwiftyGPIO

struct LogDataCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "log",
                                                    abstract: "Read data from an I2C sensor.",
                                                    discussion: "Data is read from an I2C sensor and logged to stdout.",
                                                    version: "0.1.",
                                                    shouldDisplay: true)

    @Option(help: "The board for connecting via I2C")
    var board: SupportedBoard = SupportedBoard.RaspberryPi4
    
    func run() throws {
        let sensor = I2CAMGSensor(board: board)
        Task {
            for try await data in sensor.data {
                print(Date())
                data.rawData.logPagedData()
                print()
            }
        }
        
        print("Putting the main thread into a run loop")
        RunLoop.main.run()

    }
}
