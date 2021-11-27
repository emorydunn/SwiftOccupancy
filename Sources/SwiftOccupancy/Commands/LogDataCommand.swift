//
//  LogDataCommand.swift
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
                                                    discussion: "Data is read from an I2C sensor and logged to stdout and optionally saved to a file.",
                                                    version: "0.1.",
                                                    shouldDisplay: true)
    
    @Option(help: "The board for connecting via I2C")
    var board: SupportedBoard = SupportedBoard.RaspberryPi4
    
    @Option(help: "Write the logged data to the specified file.")
    var outputURL: URL?
    
    func run() throws {

        let sensor = I2CAMGSensor(board: board)
        
        Task {
            var collectedData: [SensorPayload] = []
            
            let process = Process()
            
            process.terminationHandler = { process in
                print("Caught \(process.terminationReason)")
                self.saveData(collectedData)
            }
            
            for try await data in sensor.data {
                print(Date())
                data.rawData.logPagedData()
                print()

                collectedData.append(data)
                
            }
        }
        
        print("Putting the main thread into a run loop")
        RunLoop.main.run()

    }
    
    func saveData(_ collectedData: [SensorPayload]) {
        guard let url = outputURL else { return }
        
        
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        
        do {
            print("Encoding logged data")
            let data = try encoder.encode(collectedData)
            try data.write(to: url)
            print("Log written to \(url.path)")
        } catch {
            print(error)
        }
        
        
        
    }
}

