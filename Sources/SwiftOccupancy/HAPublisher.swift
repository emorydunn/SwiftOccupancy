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
    
    @Option(name: .long, help: "MQTT server hostname")
    var host: String
    
    @Option(name: .long, help: "MQTT server port")
    var port: Int = 1883
    
    @Option(name: .shortAndLong, help: "MQTT username")
    var username: String?
    
    @Option(name: .shortAndLong, help: "MQTT password")
    var password: String?
    
    @Option(help: "The Client ID for the MQTT server")
    var clientID: String = "SwiftOccupancy-\(Int.random(in: 0..<100))"
    
    @Option(help: "The board for connecting via I2C")
    var board: SupportedBoard = SupportedBoard.RaspberryPi4
    
    @Option(help: "The top room name")
    var topRoom: Room = .æther
    
    @Option(help: "The bottom room name")
    var bottomRoom: Room = .æther
    
    func run() throws {
        
        let client = AsyncMQTTClient(
            host: host,
            port: port,
            clientID: clientID,
            cleanSession: true,
            username: username,
            password: password)
        
        let publisher = HAMQTTPublisher(board: board, client: client, topRoom: topRoom, bottomRoom: bottomRoom)
        
        Task {
            
            print("Connecting to MQTT server 'mqtt://\(host):\(port)'")
            try await client.connect()
            
            try await publisher.publishData()
        }
        
        print("Putting the main thread into a run loop")
        RunLoop.main.run()

    }
}
