//
//  PiSensorManager.swift
//  
//
//  Created by Emory Dunn on 9/12/21.
//

import Foundation
import MQTT
import SwiftyGPIO

public class PiSensorManager: Decodable {
    public let sensor: PiSensor
    public let mqttBroker: HAMQTTConfig
    public let board: SupportedBoard
    
    public func begin() {
        // Begin monitoring data
        let client = mqttBroker.makeClient()
        
        sensor.monitorRooms(from: client)
        sensor.monitorSensor(on: SwiftyGPIO.hardwareI2Cs(for: board)![1])
        
        RunLoop.main.run()
    }
}
