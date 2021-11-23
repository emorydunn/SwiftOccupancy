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

struct MQTTOccupancyCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "mqtt",
                                                    abstract: "Read data from an MQTT sensor.",
                                                    discussion: "Data is read from an MQTT sensor, occupancy changes are parsed and published to Home Assistant via MQTT.",
                                                    version: "0.1.",
                                                    shouldDisplay: true)
    
    @OptionGroup var mqtt: MQTTOptions

    @Option(help: "The MQTT sensor name")
    var sensor: String
    
    @OptionGroup var rooms: RoomOptions

    func run() throws {
        
        let topic = "swift-occupancy/sensor/\(sensor)/data"
        
        let client = mqtt.makeClient(clientID: rooms.clientID)
        
        let sensor = MQTTAMGSensor(client: client, topic: topic)

        let publisher = HAMQTTPublisher(sensor: sensor,
                                        client: client,
                                        topRoom: rooms.topRoom,
                                        bottomRoom: rooms.bottomRoom)
        
        Task {
            
            print("Connecting to MQTT server 'mqtt://\(mqtt.host):\(mqtt.port)'")
            try await client.connect()
            
            publisher.setupHA()
            
            try await publisher.publishData()
        }
        
        print("Putting the main thread into a run loop")
        RunLoop.main.run()

    }
}
