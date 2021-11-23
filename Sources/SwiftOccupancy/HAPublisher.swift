//
//  File.swift
//  
//
//  Created by Emory Dunn on 11/23/21.
//

import Foundation
import ArgumentParser
import RoomOccupancyKit
import SwiftyGPIO

struct HAOccupancyPublisher: ParsableCommand {
    
    static var configuration = CommandConfiguration(commandName: "ha-publish",
                                                    abstract: "Publish occupancy to HA.",
                                                    discussion: "Data is read from an I2C sensor, occupancy changes are parsed and published to Home Assistant via MQTT.",
                                                    version: "0.1.",
                                                    shouldDisplay: true)
    
    @OptionGroup var mqtt: MQTTOptions

    @Option(help: "The board for connecting via I2C")
    var board: SupportedBoard = SupportedBoard.RaspberryPi4
    
    @Option(help: "The top room name")
    var topRoom: Room = .æther
    
    @Option(help: "The bottom room name")
    var bottomRoom: Room = .æther
    
    func run() throws {
        
        let client = mqtt.makeClient(clientID: "\(topRoom)-\(bottomRoom)")
        
        let publisher = HAMQTTPublisher(board: board, client: client, topRoom: topRoom, bottomRoom: bottomRoom)
        
        Task {
            
            print("Connecting to MQTT server 'mqtt://\(mqtt.host):\(mqtt.port)'")
            try await client.connect()
            
            try await publisher.publishData()
        }
        
        print("Putting the main thread into a run loop")
        RunLoop.main.run()

    }
}
