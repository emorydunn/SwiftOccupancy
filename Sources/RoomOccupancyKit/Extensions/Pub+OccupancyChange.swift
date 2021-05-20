//
//  Pub+OccupancyChange.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/19/21.
//

import Foundation
import OpenCombineShim

extension Publisher where Output == OccupancyChange, Failure == Never {
    
    /// Apply the published delta to the given occupancy count
    /// - Parameter occupancy: Current occpancy
    /// - Returns: A publisher with new totals
    func applyOccupancyDelta(to occupancy: [String: Int]) -> AnyPublisher<OccupancyUpdate, Never> {
        
        var localOccupancy = occupancy
        var updated = [String: Int]()
        
        return self.map { change in
            
            change.delta.forEach { room, delta in
                let newCount: Int
                
                if change.absolute {
                    newCount = delta
                } else {
                    let currentCount = localOccupancy[room] ?? 0 // Find the room, or default to 0
                    newCount = Swift.max(0, currentCount + delta) // Apply the delta, clamping to 0
                }
                
                // Update or create the room
                localOccupancy[room] = newCount
                updated[room] = newCount
            }
            
            return OccupancyUpdate(newValues: localOccupancy, changes: updated)
        }
        .eraseToAnyPublisher()
    }
    
}
