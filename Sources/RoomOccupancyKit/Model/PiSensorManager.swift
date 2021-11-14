//
//  PiSensorManager.swift
//  
//
//  Created by Emory Dunn on 9/12/21.
//

import Foundation
import SwiftyGPIO
import MQTTKit

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
        var options = MQTTOptions(host: mqtt.host, port: mqtt.port)
        
        options.username = mqtt.username
        options.password = mqtt.password
        options.clientId = sensor.id

        let client = MQTTSession(options: options)
        
        client.connect { success in
            print("Connected to MQTT server:", success)
        }
  
        sensor.monitorRooms(from: client)
        sensor.monitorSensor(on: SwiftyGPIO.hardwareI2Cs(for: board)![1])
        
        RunLoop.main.run()
    }
}
