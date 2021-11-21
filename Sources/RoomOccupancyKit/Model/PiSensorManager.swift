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
    
    public enum Datasource: Decodable {
        case i2c(SupportedBoard)
        case mqtt
    }
    
    public struct MQTTSettings: Decodable {
        let host: String
        let port: Int
        let username: String
        let password: String
    }
    
    public let sensor: PiSensor
    public let mqtt: MQTTSettings?

    public let datasource: Datasource
    
    public let debug: Bool
    public let parseData: Bool
    
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
        case .i2c(let supportedBoard):
            print("Connecting to I2C AMG88 Sensor")
            sensor.monitorSensor(on: SwiftyGPIO.hardwareI2Cs(for: supportedBoard)![1], parseData: parseData)
        case .mqtt:
            print("Connecting to MQTT AMG88 Sensor")
            if let mqttClient = mqttClient {
                sensor.monitorSensor(on: mqttClient, parseData: parseData)
            } else {
                print("No MQTT settings were provided, can't connect to sensor.")
            }
            
        }
        
        
        RunLoop.main.run()
    }
}
