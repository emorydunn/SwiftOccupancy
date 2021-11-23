//
//  AMGSensorProtocol.swift
//  
//
//  Created by Emory Dunn on 11/22/21.
//

import Foundation

/// A protocol which provides an asynchronous stream of sensor data.
public protocol AMGSensorProtocol {

    var data: AsyncThrowingStream<SensorPayload, Error> { get }
    
}
