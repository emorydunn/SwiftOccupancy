//
//  Pub+OccupancyChange.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/19/21.
//

import Foundation
import OpenCombineShim

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Publisher where Output == OccupancyChange, Failure == Never {
    
    /// Apply the published delta to the given occupancy count.
    ///
    /// The current occpancy passed to this method is updated to reflect the new
    /// room totals.
    /// - Parameter occupancy: Current occpancy
    /// - Returns: A publisher with only the rooms who's occupancy changed. 
    func applyOccupancyDelta(to house: House) {
        self.sink { change in
            change.update(house)
        }
        .store(in: &house.tokens)

    }

}

struct HAState: CustomStringConvertible {
    let domain: String
    let name: String
    let state: Any
    let attributes: [String: Any]
    
    var description: String {
        "\(domain).\(name)"
    }
    
    var payload: [String: Any] {
        [
            "state": state,
            "attributes": attributes
        ]
    }
}

extension Publisher where Output == [Room: Int], Failure == Never {
    
    func publishtoHomeAssistant(using config: HAConfig) -> AnyPublisher<HTTPURLResponse, URLError> {
        self
            .pairwise()
            .map { previous, new in
                new.filter { previous[$0.key] != $0.value }
            }
            .flatMap {
                $0.publisher
            }
//            .print("Sending HA State")
            .filter { $0.key.publishStateChanges }
            .map { change in
                HAState(domain: "sensor",
                        name: change.key.sensorName,
                        state: change.value,
                        attributes: [
                                "friendly_name": "\(change.key) Occupancy",
                                "unit_of_measurement": change.value.personUnitCount,
                                "icon": change.value.icon
                            ]
                        )
            }
            .publishState(using: config)
    }
    
    
}

extension Publisher where Output == HAState, Failure == Never {
    func publishState(using config: HAConfig) -> AnyPublisher<HTTPURLResponse, URLError> {
        self
            .print("Sending State to HA")
            .map { state -> URLRequest in
                var request = URLRequest(url: config.url.appendingPathComponent("/api/states/\(state)"))
                request.httpMethod = "POST"
                request.setValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")

                request.httpBody = try? JSONSerialization.data(withJSONObject: state.payload, options: [])
                
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
    }
}
