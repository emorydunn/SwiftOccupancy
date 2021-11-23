//
//  main.swift
//  
//
//  Created by Emory Dunn on 5/20/21.
//

import Foundation
import RoomOccupancyKit
import ArgumentParser
import SwiftyGPIO

struct MQTTPublisher: ParsableCommand {
    
    static var configuration = CommandConfiguration(commandName: "raw-data",
                                                    abstract: "Publish raw sensor data to MQTT.",
                                                    discussion: "Data is read from an I2C sensor and published via MQTT.",
                                                    version: "0.1.",
                                                    shouldDisplay: true)
    
    @OptionGroup var mqtt: MQTTOptions
    
    @Option(help: "The Client ID for the MQTT server")
    var clientID: String = "SwiftOccupancy-\(Int.random(in: 0..<100))"
    
    @Option(help: "The board for connecting via I2C")
    var board: SupportedBoard = SupportedBoard.RaspberryPi4
    
    func run() throws {
        
        let client = mqtt.makeClient(clientID: clientID)
        
        let topic = "swift-occupancy/sensor/\(clientID)/data"
        
        let publisher = SensorDataMQTTPublisher(board: board, client: client, topic: topic)
        
        Task {
            
            print("Connecting to MQTT server 'mqtt://\(mqtt.host):\(mqtt.port)'")
            try await client.connect()
            
            try await publisher.publishData(retain: false, qos: .atLeastOnce)
        }
        
        print("Putting the main thread into a run loop")
        RunLoop.main.run()

    }
}
