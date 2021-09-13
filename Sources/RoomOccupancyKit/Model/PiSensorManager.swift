//
//  PiSensorManager.swift
//  
//
//  Created by Emory Dunn on 9/12/21.
//

import Foundation
import SwiftyGPIO

public class PiSensorManager: Decodable {
    
    public struct MQTTSettings: Decodable {
        let host: String
        let port: Int
        let username: String
        let password: String
    }
    
    public let sensor: PiSensor
//    public let mqttBroker: HAMQTTConfig
    public let mqtt: MQTTSettings
    public let board: SupportedBoard
    
    public func begin() {
        var options = LightMQTT.Options()
        options.username = mqtt.username
        options.password = mqtt.password
        options.port = mqtt.port
        options.clientId = sensor.id
        
        let client = LightMQTT(host: mqtt.host, options: options)
  
        sensor.monitorRooms(from: client)
        sensor.monitorSensor(on: SwiftyGPIO.hardwareI2Cs(for: board)![1])
        
        RunLoop.main.run()
    }
}
