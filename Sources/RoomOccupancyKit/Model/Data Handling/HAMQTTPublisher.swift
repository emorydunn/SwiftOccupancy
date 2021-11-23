//
//  File.swift
//  
//
//  Created by Emory Dunn on 11/22/21.
//

import Foundation
import MQTT
import SwiftyGPIO

/// A class that consumes occupancy changes and publishes the state to Home Assistant.
public struct HAMQTTPublisher {
    
    public let sensor: AMGSensorProtocol
    
    public let client: AsyncMQTTClient
    
    public let counter: OccupancyCounter
    
    public init(sensor: AMGSensorProtocol, client: AsyncMQTTClient, counter: OccupancyCounter) {
        self.sensor = sensor
        self.client = client
        self.counter = counter
    }
    
    public init(sensor: AMGSensorProtocol, client: AsyncMQTTClient, topRoom: Room = .æther, bottomRoom: Room = .æther) {
        self.sensor = sensor
        self.client = client
        self.counter = OccupancyCounter(sensor: sensor, topRoom: topRoom, bottomRoom: bottomRoom)
    }
    
    public init(board: SupportedBoard, client: AsyncMQTTClient, topRoom: Room = .æther, bottomRoom: Room = .æther) {
        self.sensor = I2CAMGSensor(board: board)
        self.client = client
        self.counter = OccupancyCounter(sensor: sensor, topRoom: topRoom, bottomRoom: bottomRoom)
    }
    
    public func publishData() async throws {
        try await counter.publishChanges(to: client)
    }
}
