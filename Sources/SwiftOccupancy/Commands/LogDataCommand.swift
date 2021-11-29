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
                                                    discussion: "Data is read from an I2C sensor and logged to stdout or saved to disk.",
                                                    version: "0.1.",
                                                    shouldDisplay: true)
    
    @Option(help: "The board for connecting via I2C")
    var board: SupportedBoard = SupportedBoard.RaspberryPi4
    
    @Option(help: "The threshold to use when calculating clusters.")
    var deltaThreshold: Float = 2
    
    @Flag(name: .customLong("print"), inversion: FlagInversion.prefixedNo, help: "Log data to stdout.")
    var logToScreen: Bool = true
    
    @Option(help: "Write the logged data to the specified folder.")
    var outputURL: Directory?
    
    static var signalReceived: sig_atomic_t = 0
    
    func run() throws {

        let sensor = I2CAMGSensor(board: board)
        
        Task {
            var collectedData: [SensorPayload] = []
            
            // Capture SIGINT so we can save the data
            signal(SIGINT) { signal in
                LogDataCommand.signalReceived = 1
            }
            
            for try await data in sensor.data {
                if logToScreen {
                    print(Date())
                    data.rawData.logPagedData()
                    print()
                }

                collectedData.append(data)
                
                if LogDataCommand.signalReceived == 1 {
                    saveData(collectedData)
                }
                
            }
        }

        print("Putting the main thread into a run loop")
        RunLoop.main.run()

    }
    
    func saveData(_ collectedData: [SensorPayload]) {
        guard let url = outputURL?.url.appendingPathComponent(String(describing: Date())) else {
            LogDataCommand.exit(withError: nil)
        }
        
        let encoder = JSONEncoder()
        
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            
            print("Encoding logged data")
            let data = try encoder.encode(collectedData)
            try data.write(to: url.appendingPathComponent("raw_data.json"))
            
            print("Saving PNGs")
            try collectedData.enumerated().forEach { index, data in
                let cluster = Cluster(from: data, deltaThreshold: deltaThreshold)
                
                let fileURL = url.appendingPathComponent("frame-\(index).png")
                try data.drawImage(cluster: cluster).writePNG(atPath: fileURL.path)
            }
            
            print("Logged data written to \(url.path)")
            LogDataCommand.exit(withError: nil)
        } catch {
            LogDataCommand.exit(withError: error)
        }
        
        
        
        
    }
}

