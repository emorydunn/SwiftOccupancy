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

    public let datasource: String
    
    public var debug: Bool = false
    public var parseData: Bool = true
    
    public enum CodingKeys: String, CodingKey {
        case sensor, mqtt, datasource, debug, parseData
    }
    
    public func begin() {
        
        var mqttClient: MQTTClient? = nil
        
        if let mqtt = mqtt {
            print("Connecting to MQTT server 'mqtt://\(mqtt.host):\(mqtt.port)'")
            
            mqttClient = MQTTClient(host: mqtt.host,
                                    port: mqtt.port,
                                    clientID: sensor.clientID,
                                    cleanSession: true,
                                    keepAlive: 30,
                                    willMessage: sensor.statusMessage(false),
                                    username: mqtt.username,
                                    password: mqtt.password)

            sensor.monitorRooms(from: mqttClient!)
            
            if debug {
                sensor.debugSensor(with: mqttClient!)
            }
        }
        
        switch datasource {
        case "mqtt":
            print("Connecting to MQTT AMG88 Sensor")
            if let mqttClient = mqttClient {
                sensor.monitorSensor(on: mqttClient, parseData: parseData)
            } else {
                print("No MQTT settings were provided, can't connect to sensor.")
            }
        default:
            guard let board = SupportedBoard(rawValue: datasource) else {
                print("'\(datasource)' is not a supported board")
                break
            }
            
            print("Connecting to I2C AMG88 Sensor")
            sensor.monitorSensor(on: SwiftyGPIO.hardwareI2Cs(for: board)![1], parseData: parseData)
            
        }

        RunLoop.main.run()
    }
}
