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
    public let mqtt: MQTTSettings?
    public let board: SupportedBoard?
    
    public enum CodingKeys: String, CodingKey {
        case sensor, mqtt, board
    }
    
    public func begin() {
        
        if let mqtt = mqtt {
            print("Connecting to MQTT server 'mqtt://\(mqtt.host):\(mqtt.port)'")
            
            let mqttClient = MQTTClient(host: mqtt.host,
                                    port: mqtt.port,
                                    clientID: sensor.clientID,
                                    cleanSession: true,
                                    keepAlive: 30,
                                    willMessage: PublishMessage(topic: "swift-occupancy/sensor/will", payload: "\(sensor.id) disconnected", retain: false, qos: .atMostOnce),
                                    username: mqtt.username,
                                    password: mqtt.password)

            sensor.monitorRooms(from: mqttClient)
        }
        
        if let board = board {
            print("Connecting to AMG88 Sensor")
            sensor.monitorSensor(on: SwiftyGPIO.hardwareI2Cs(for: board)![1])
        }
        
        
        RunLoop.main.run()
    }
}
