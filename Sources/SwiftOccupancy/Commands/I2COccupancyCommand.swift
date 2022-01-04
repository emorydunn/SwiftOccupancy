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

struct I2COccupancyCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "i2c",
                                                    abstract: "Read data from an I2C sensor.",
                                                    discussion: "Data is read from an I2C sensor, occupancy changes are parsed and published to Home Assistant via MQTT.",
                                                    version: "0.1.",
                                                    shouldDisplay: true)
    
    @OptionGroup var mqtt: MQTTOptions
    
    @OptionGroup var sensorOptions: SensorOptions

    @OptionGroup var rooms: RoomOptions
    
    @OptionGroup var counterOptions: CounterOptions

    func run() throws {
        
        let client = mqtt.makeClient(clientID: rooms.clientID)
        
        let counter = OccupancyCounter(topRoom: rooms.topRoom, bottomRoom: rooms.bottomRoom)
        counterOptions.configureCounter(counter)

        let publisher = HAMQTTPublisher(board: sensorOptions.board,
                                        address: sensorOptions.address.address,
                                        client: client,
                                        counter: counter,
                                        publishImage: mqtt.camera)
        
        Task {
            
            print("Connecting to MQTT server 'mqtt://\(mqtt.host):\(mqtt.port)' as '\(client.clientID)'")
            try await client.connect()
            
            publisher.setupHA()
            
            if rooms.resetCounts {
                publisher.counter.resetRoomCounts(with: client)
            }
            
            try await publisher.publishData()
            
            
        }
        
        print("Putting the main thread into a run loop")
        RunLoop.main.run()

    }
}
