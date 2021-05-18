//
//  SensorManager.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/17/21.
//

import Foundation
import Combine

class SensorManager: ObservableObject {
    
    var sensors: [Sensor]
    @Published var occupancy: [String: Int]
    
    var tokens: [AnyCancellable] = []
    
    init(sensors: [Sensor], occupancy: [String: Int]? = nil) {
        self.sensors = sensors
        
        // Use the given occupancy counts,
        // otherwise set all rooms to 0
        if let occupancy = occupancy {
            self.occupancy = occupancy
        } else {
            self.occupancy = [:]
            sensors.forEach {
                self.occupancy[$0.topName] = 0
                self.occupancy[$0.bottomName] = 0
            }
        }

    }
    
    func monitorSensors() {
        
        // Cancel any existing subscriptions
        tokens.forEach { $0.cancel() }
        
        sensors.forEach {
            // Begin monitoring data
            $0.monitorData()
            
            // Merge the deltas
            $0.$currentDelta
                .map { $0.delta }
                .applyOccupancyDelta(to: occupancy)
                .removeDuplicates()
                .print()
//                .receive(on: RunLoop.main)
                .assign(to: &$occupancy)


        }
        
            
    }
    
    
    func updateCounts(with data: [String: Int]) {
        data.forEach { room, delta in
            
            let currentCount = occupancy[room] ?? 0 // Find the room, or default to 0
            let newCount = max(0, currentCount + delta) // Apply the delta, clamping to 0

            print("Updating \(room) from \(currentCount) to \(newCount)")
            
            // Update or create the room
            occupancy[room] = newCount
        }

    }
}

extension Publisher where Output == [String: Int], Failure == Never {
    
    /// Apply the published delta to the given occupancy count
    /// - Parameter occupancy: Current occpancy
    /// - Returns: A publisher with new totals
    func applyOccupancyDelta(to occupancy: [String: Int]) -> AnyPublisher<[String: Int], Never> {

        var localOccupancy = occupancy
        
        return self.map { data in
            data.forEach { room, delta in

                let currentCount = localOccupancy[room] ?? 0 // Find the room, or default to 0
                let newCount = Swift.max(0, currentCount + delta) // Apply the delta, clamping to 0

                // Update or create the room
                localOccupancy[room] = newCount
            }

            return localOccupancy
        }
        .eraseToAnyPublisher()
    }
}
