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
    
    @OptionGroup var sensorOptions: SensorOptions
    
    @Option(help: "The threshold to use when calculating clusters.")
    var deltaThreshold: Float = 2
    
    @Flag(help: "Don't render pixels that fall below the threshold.")
	var ignoreBelowThreshold: ThresholdBehavior = .include
    
    @Flag(name: .customLong("print"), inversion: FlagInversion.prefixedNo, help: "Log data to stdout.")
    var logToScreen: Bool = true
    
    @Flag(name: .customLong("annotate"), inversion: FlagInversion.prefixedNo, help: "Annotate PNGs with debug data.")
    var annotateData: Bool = true
    
    @Flag(inversion: FlagInversion.prefixedEnableDisable, help: "Render PNGs as greyscale.")
    var greyscale: Bool = false
    
    @Option(help: "Write the logged data to the specified folder.")
    var outputURL: Directory?

	@Option(help: "The min temperature")
	var minTemperature: Float = 10
	@Option(help: "The max temperature")
	var maxTemperature: Float = 35


    static var signalReceived: sig_atomic_t = 0
    
    func run() throws {

        let sensor = I2CAMGSensor(board: sensorOptions.board, address: sensorOptions.address.address)
        let counter = OccupancyCounter(topRoom: .room("Top"), bottomRoom: .room("Bottom"))
        
        Task {
            var collectedData: [Int: SensorPayload] = [:]
			var events: [Int: (OccupancyChange.Direction, Int, Int)] = [:]

            // Capture SIGINT so we can save the data
            signal(SIGINT) { signal in
                LogDataCommand.signalReceived = 1
            }
            
            for try await data in sensor.data {
                let frameNumber = collectedData.count
                
                let date = Date()
                if logToScreen {
                    print(date)
                    data.rawData.logPagedData()
                    print()
                }

                if let change = try counter.countChanges(using: data) {
					events[frameNumber] = (change.direction, counter.topRoomCount, counter.bottomRoomCount)
                }

                collectedData[frameNumber] = data
                
                
                if LogDataCommand.signalReceived == 1 {
                    saveData(collectedData, events: events)
                }
                
            }
        }

        print("Putting the main thread into a run loop")
        RunLoop.main.run()

    }
    
    func saveData(_ collectedData: [Int: SensorPayload], events: [Int: (OccupancyChange.Direction, Int, Int)]) {
        let date = String(describing: Date()).replacingOccurrences(of: " ", with: "_")
        
        guard let url = outputURL?.url.appendingPathComponent(date) else {
            LogDataCommand.exit(withError: nil)
        }
        
        let encoder = JSONEncoder()
        
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            
            print("Encoding logged data")
            let data = try encoder.encode(collectedData)
            try data.write(to: url.appendingPathComponent("raw_data.json"))
            
            print("Encoding logged events")
			var csv = "frame,direction,top_count,bottom_count\n"
			let sortedEvents = events.sorted { lhs, rhs in
				lhs.key < rhs.key
			}
			let csvData = sortedEvents.map { frame, change in
				"\(String(format: "%04d", frame)),\(change.0),\(change.1),\(change.1)"
			}.joined(separator: "\n")

			csv.append(csvData)

			try csv.write(to: url.appendingPathComponent("events.csv"), atomically: true, encoding: .utf8)
            
            print("Saving PNGs")
            try collectedData.forEach { index, data in
                let cluster = Cluster(from: data, deltaThreshold: deltaThreshold)

                let paddedIndex = String(format: "%04d", index)
                let fileURL = url.appendingPathComponent("frame-\(paddedIndex).png")
                try data.drawImage(cluster: cluster,
								   minTemperature: minTemperature,
								   maxTemperature: maxTemperature,
                                   ignoreBelowThreshold: ignoreBelowThreshold,
                                   annotateData: annotateData,
                                   greyscale: greyscale
                ).writePNG(atPath: fileURL.path)
            }
            
            print("Logged data written to \(url.path)")
            LogDataCommand.exit(withError: nil)
        } catch {
            LogDataCommand.exit(withError: error)
        }
        
        
        
        
    }
}

