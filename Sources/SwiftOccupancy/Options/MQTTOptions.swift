//
//  MQTTOptions.swift
//  
//
//  Created by Emory Dunn on 11/23/21.
//

import Foundation
import ArgumentParser
import RoomOccupancyKit
import MQTT

struct MQTTOptions: ParsableArguments {
    @Option(name: .long, help: "MQTT server hostname")
    var host: String
    
    @Option(name: .long, help: "MQTT server port")
    var port: Int = 1883
    
    @Option(name: .shortAndLong, help: "MQTT username")
    var username: String?
    
    @Option(name: .shortAndLong, help: "MQTT password")
    var password: String?
    
    @Flag(name: .long, inversion: FlagInversion.prefixedEnableDisable, help: "Publish the rendered sensor view.")
    var camera: Bool = false
    
    func makeClient(clientID: String, willMessage: PublishMessage? = nil) -> AsyncMQTTClient {
        AsyncMQTTClient(
            host: host,
            port: port,
            clientID: clientID,
            cleanSession: true,
            willMessage: willMessage,
            username: username,
            password: password)
    }
}
