//
//  I2CSensor.swift
//  
//
//  Created by Emory Dunn on 11/22/21.
//

import Foundation
import SwiftyGPIO
import AMG88

/// A sensor that reads its data from an I2C interface.
public struct I2CAMGSensor: AMGSensorProtocol {

    public let sensor: AMG88Protocol

    public init(interface: I2CInterface) {
        self.sensor = AMG88(interface)
    }
    
    public init(board: SupportedBoard) {
        print("Initializing AMG for board \(board)")
        self.sensor = AMG88(SwiftyGPIO.hardwareI2Cs(for: board)![1])
    }
    
    public init(sensor: AMG88Protocol) {
        self.sensor = sensor
    }

    public var data: AsyncThrowingStream<SensorPayload, Error> {

        print("Beginning to monitor AMG sensor")
        
        return AsyncThrowingStream { continuation in

            let timer = Timer(timeInterval: 0.1, repeats: true) { timer in
                let pixels = sensor.readPixels()
                let therm = sensor.readThermistor()

                do {
                    let data = try SensorPayload(data: pixels, thermistorTemperature: therm)
                    continuation.yield(data)
                } catch {
                    continuation.finish(throwing: error)
                }

            }
            
            continuation.onTermination = { @Sendable _ in
                timer.invalidate()
            }

            RunLoop.main.add(timer, forMode: .common)
        }
    }

}
