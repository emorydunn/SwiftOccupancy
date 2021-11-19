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
    public let mqtt: MQTTSettings?
    public let board: SupportedBoard
    
    public func begin() {
        
        if let mqtt = mqtt {
            print("Connecting to MQTT server \(mqtt.host):\(mqtt.port)")
            
            var options = MQTTOptions(host: mqtt.host, port: mqtt.port)
            
            options.username = mqtt.username
            options.password = mqtt.password
            options.clientId = sensor.id

            let client = MQTTSession(options: options)
            
            client.didRecieveConack = { message in
                switch message {
                case .accepted:
                    print("Server accepted the connection.")
                case .badUsernameOrPassword:
                    print("Error: Bad username or password")
                case .identifierRejected:
                    print("Error: Identifier '\(self.sensor.id)' was rejected")
                case .notAuthorized:
                    print("Error: Not authorized")
                case .reserved:
                    print("Error: Reserved")
                case .serverUnavailable:
                    print("Error: Server unavailable")
                case .unacceptableProtocolVersion:
                    print("Error: Unacceptable protocol version")
                }
            }
            
            client.connect { success in
                print("Connected to MQTT server:", success)
            }
      
            sensor.monitorRooms(from: client)
        }
        
        print("Connecting to AMG88 Sensor")
        sensor.monitorSensor(on: SwiftyGPIO.hardwareI2Cs(for: board)![1])
        
        RunLoop.main.run()
    }
}
