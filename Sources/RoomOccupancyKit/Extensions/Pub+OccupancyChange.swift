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
    func applyOccupancyDelta(to occupancy: [Room: Int]) -> AnyPublisher<OccupancyUpdate, Never> {
        
        var localOccupancy = occupancy
        var updated = [Room: Int]()
        
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
    
    /// Apply the published delta to the given occupancy count
    /// - Parameter occupancy: Current occpancy
    /// - Returns: A publisher with new totals
    func applyOccupancyDelta(to occupancy: inout [Room: Int]) -> AnyPublisher<[Room: Int], Never> {
        
        var localOccupancy = occupancy
        var updated = [Room: Int]()
        
        let pub: AnyPublisher<[Room: Int], Never> = self.map { change in
            
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
            

            return updated
        }
        .eraseToAnyPublisher()
        
        occupancy = localOccupancy
        return pub
    }
    
    
    
}

extension Publisher where Output == [Room: Int], Failure == Never {
    
    func publishtoHomeAssistant(using config: HAConfig) -> AnyPublisher<HTTPURLResponse, URLError> {
        self
            .flatMap {
                $0.publisher
            }
            .print("Sending HA State")
            .filter { $0.key.publishStateChanges }
            .map { change -> URLRequest in
                var request = URLRequest(url: config.url.appendingPathComponent("/api/states/sensor.\(change.key.slug)_occupancy_count"))
                request.httpMethod = "POST"
                request.setValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
                
                let jsonBody: [String: Any] = [
                    "state": change.value,
                    "attributes": [
                        "friendly_name": "\(change.key) Occupancy",
                        "unit_of_measurement": change.value.personUnitCount,
                        "icon": change.value.icon
                    ]
                ]
                
                request.httpBody = try? JSONSerialization.data(withJSONObject: jsonBody, options: [])
                
                return request
            }
            .flatMap { request -> URLSession.DataTaskPublisher in
                URLSession.shared.dataTaskPublisher(for: request)
            }
            .retry(3)
            .compactMap { element -> HTTPURLResponse? in
                element.response as? HTTPURLResponse
            }
            .eraseToAnyPublisher()
//            .sink {
//                print($0)
//            } receiveValue: { value in
//                guard value.statusCode != 200 else { return }
//                print("ERROR: \(value.statusCode)")
//            }
    }
    
}
