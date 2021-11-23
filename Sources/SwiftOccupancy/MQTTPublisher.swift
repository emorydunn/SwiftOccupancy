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

extension SupportedBoard: ExpressibleByArgument { }

@main
struct MQTTPublisher: ParsableCommand {
    
    @Option(help: "MQTT server hostname")
    var host: String
    
    @Option(help: "MQTT server port")
    var port: Int = 1883
    
    @Option(help: "MQTT username")
    var username: String?
    
    @Option(help: "MQTT password")
    var password: String?
    
    @Option(help: "The Client ID for the MQTT server")
    var clientID: String = "SwiftOccupancy-\(Int.random(in: 0..<100))"
    
    @Option(help: "The board for connecting via I2C")
    var board: SupportedBoard = SupportedBoard.RaspberryPi4
    
    func run() throws {
        
        let client = AsyncMQTTClient(
            host: host,
            port: port,
            clientID: clientID,
            cleanSession: true,
            username: username,
            password: password)
        
        let topic = "swift-occupancy/sensor/\(clientID)/data"
        
        let publisher = SensorDataMQTTPublisher(board: board, client: client, topic: topic)
        
        Task {
            
            print("Connecting to MQTT server 'mqtt://\(host):\(port)'")
            try await client.connect()
            
            try await publisher.publishData(retain: false, qos: .atLeastOnce)
        }
        
        print("Putting the main thread into a run loop")
        RunLoop.main.run()
        
//        let sensor = I2CAMGSensor(board: bo)
//        let client = AsyncMQTTClient(client: MQTTClient)
    }
}
//
//// Default to the Home Assistant add-on config
//var configFile: URL = URL(fileURLWithPath: "/data/options.json")
//
//// If the user specified a config, use that instead
//if CommandLine.arguments.count == 2 {
//    configFile = URL(fileURLWithPath: CommandLine.arguments[1])
//}
//
//// Parse the file
//let data: Data
//do {
//    data = try Data(contentsOf: configFile)
//} catch {
//    print("There was a problem reading \(configFile.path).")
//    print(error.localizedDescription)
//    exit(1)
//}
//
//do {
//    let manager = try JSONDecoder().decode(PiSensorManager.self, from: data)
//    manager.begin()
//} catch {
//    print("There was a problem decoding the config file.")
//    print(error)
//    exit(1)
//}
