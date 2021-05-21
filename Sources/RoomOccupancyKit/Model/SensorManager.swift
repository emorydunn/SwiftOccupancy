//
//  SensorManager.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/17/21.
//

import Foundation
import OpenCombineShim

public class SensorManager: ObservableObject, Decodable {
    
    public var sensors: [Sensor]
    public let homeAssistant: HAConfig
    
    @Published var occupancy: [Room: Int]
    @Published var deltasToSend: (room: String, status: Int)?
    
    var tokens: [AnyCancellable] = []
    
    public init(sensors: [Sensor], haConfig: HAConfig, occupancy: [Room: Int]? = nil) {
        self.sensors = sensors
        self.homeAssistant = haConfig
        
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
    
    // MARK: Codable
    public enum CodingKeys: String, CodingKey {
        case sensors, homeAssitant
    }
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.sensors = try container.decode([Sensor].self, forKey: .sensors)
        self.homeAssistant = try container.decode(HAConfig.self, forKey: .homeAssitant)
        self.occupancy = [:]
        
    }
    
    public func monitorSensors() {

        sensors.forEach {
            // Begin monitoring data
            $0.monitorData()
        }
        
        let changes = sensors.publisher
            .flatMap { $0.$currentDelta }
            .applyOccupancyDelta(to: occupancy)
            .print("SensorManager Sub")
            .share()
        
        // Update the occupancy
        changes
            .map { $0.newValues }
            .removeDuplicates()
            .assign(to: &$occupancy)
        
        // Publish the changed values
        changes
            .map { $0.changes }
            .flatMap {
                $0.publisher
            }
            .print("HA State")
            .filter { $0.key.publishStateChanges }
            .map { change -> URLRequest in
                var request = URLRequest(url: self.homeAssistant.url.appendingPathComponent("/api/states/sensor.\(change.key.lowercased())_occupancy_count"))
                request.httpMethod = "POST"
                request.setValue("Bearer \(self.homeAssistant.token)", forHTTPHeaderField: "Authorization")
                
                let jsonBody: [String: Any] = [
                    "state": change.value,
                    "attributes": [
                        "friendly_name": "\(change.key) Occupancy",
                        "unit_of_measurement": self.unit(for: change.value),
                        "icon": self.icon(for: change.value)
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
            .print()
            .sink {
                print($0)
            } receiveValue: { value in
                if value.statusCode == 200 {
//                    print("State Updated")
                } else {
                    print("ERROR: \(value.statusCode)")
                }
                
            }
            .store(in: &tokens)

            
    }
    
    func unit(for count: Int) -> String {
        count == 1 ? "person" : "people"
    }
    
    func icon(for count: Int) -> String {
        switch count {
        case 0:
            return "mdi:account-outline"
        case 1:
            return "mdi:account"
        case 2:
            return "mdi:account-multiple"
        default:
            return "mdi:account-group"
        }
    }
        
}



struct OccupancyUpdate {
    let newValues: [Room: Int]
    let changes: [Room: Int]
}
