//
//  File.swift
//  
//
//  Created by Emory Dunn on 11/22/21.
//

import Foundation
import MQTT

class MQTTDataPublisher {
    
    /// Sensor datasource
    let sensor: AMGSensorProtocol
    
    /// The client used for publishing raw data
    let client: AsyncMQTTClient
    
    init(sensor: AMGSensorProtocol, client: AsyncMQTTClient) {
        self.sensor = sensor
        self.client = client
    }
    
    func publishData() async throws {
        
        // Read data from the sensor
        
        for try await data in sensor.data {
            
        }
//        for try await change in occupancyCounter.countChanges {
//
//        }
    }
}
