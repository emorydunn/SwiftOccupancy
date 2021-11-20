//
//  PiSensorManager.swift
//  
//
//  Created by Emory Dunn on 9/12/21.
//

import Foundation
import SwiftyGPIO
import MQTT

public class PiSensorManager: Decodable {
    
    public struct MQTTSettings: Decodable {
        let host: String
        let port: Int
        let username: String
        let password: String
    }
    
    public let sensor: PiSensor
//    public let mqttBroker: HAMQTTConfig
    public let mqtt: MQTTSettings?
    public let board: SupportedBoard
    
    public func begin() {
        
        if let mqtt = mqtt {
            print("Connecting to MQTT server \(mqtt.host):\(mqtt.port)")
            
            let client = MQTTClient(host: mqtt.host,
                                    port: mqtt.port,
                                    clientID: sensor.id,
                                    cleanSession: true,
                                    keepAlive: 30,
                                    username: mqtt.username,
                                    password: mqtt.password)

            client.connect()

            sensor.monitorRooms(from: client)
        }
        
        print("Connecting to AMG88 Sensor")
        sensor.monitorSensor(on: SwiftyGPIO.hardwareI2Cs(for: board)![1])
        
        RunLoop.main.run()
    }
}
