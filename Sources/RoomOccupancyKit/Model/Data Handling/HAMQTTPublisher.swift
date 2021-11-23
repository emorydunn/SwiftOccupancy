//
//  File.swift
//  
//
//  Created by Emory Dunn on 11/22/21.
//

import Foundation
import MQTT

/// A class that consumes occupancy changes and publishes the state to Home Assistant.
struct HAMQTTPublisher {
    
    // The MQTT client
    let client: AsyncMQTTClient
    
    
}
