//
//  File.swift
//  
//
//  Created by Emory Dunn on 11/23/21.
//

import Foundation
import ArgumentParser
import RoomOccupancyKit

struct MQTTOptions: ParsableArguments {
    @Option(name: .long, help: "MQTT server hostname")
    var host: String
    
    @Option(name: .long, help: "MQTT server port")
    var port: Int = 1883
    
    @Option(name: .shortAndLong, help: "MQTT username")
    var username: String?
    
    @Option(name: .shortAndLong, help: "MQTT password")
    var password: String?
    
    func makeClient(clientID: String) -> AsyncMQTTClient {
        AsyncMQTTClient(
            host: host,
            port: port,
            clientID: clientID,
            cleanSession: true,
            username: username,
            password: password)
    }
}
