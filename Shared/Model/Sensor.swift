import Foundation
import Combine
import SwiftUI

struct OccupancyChange {
    let action: String
    let delta: [String: Int]

    static let `default` = OccupancyChange(action: "No Action", delta: [:])
}

enum Direction {
    case toTop
    case toBottom
}

class Sensor: ObservableObject, Identifiable {
    let url: URL
    
    let topName: String
    let bottomName: String
    
    let id: URL
    
    var title: String { "\(topName) / \(bottomName)" }
    
    @State var deltaThreshold: Double = 1
    @State var minClusterSize: Int = 10
    @State var averageFrameCount: Int = 2
    @State var refreshInterval: TimeInterval = 0.1
    
    @Published var currentState: SensorPayload?
    @Published var currentClusters: [Cluster] = []
    @Published var currentDelta: OccupancyChange = OccupancyChange.default
    
    public var token: AnyCancellable?
    
    init(_ url: URL, topName: String = "Top", bottomName: String = "Bottom") {
        self.url = url
        self.topName = topName
        self.bottomName = bottomName
        
        self.id = url
    }
    
    // MARK: - Combine
    
    /// A shared publisher that fetches data from the sensor.
    /// - Returns: A Publisher with the latest sensor info
    func sensorDataPublisher() -> AnyPublisher<SensorPayload, Error> {
        URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { element in
                guard let httpRespone = element.response as? HTTPURLResponse,
                      httpRespone.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                
                return element.data
            }
            .decode(type: SensorPayload.self, decoder: JSONDecoder())
            //            .share()
            .eraseToAnyPublisher()
    }
    
    /// Continually read data from the sensor and update the counts.
    /// - Parameter interval: Time interval at which to refresh
    func monitorData() {
        if token != nil {
            print("Cancelling existing read")
            token?.cancel()
        }

        // Create the timer publisher
        let pub = sensorPublisher()
            .receive(on: RunLoop.main)
            .share()
        
        // Assign to current state
        pub.assign(to: &$currentState)
            
        // Assign to cluster
        pub
            .compactMap { $0 }
            .map { data in
                self.clusterPixels(data).filter { $0.size >= self.minClusterSize }
            }
            .assign(to: &$currentClusters)
        
        $currentClusters
            .compactMap { $0.largest() } // Map the clusters to the largest
            .collect(2) // Collect the two previous clusters
            .filter { $0.count == 2 } // Ensure there are two clusters
            .map { clusters -> (Cluster, Cluster) in
                (clusters[0], clusters[1])
            }
            .print()
            .map { (previousCluser, currentCluster) -> OccupancyChange in
                var delta = [String: Int]()
                var lastAction = self.currentDelta.action

                // Parse cluster delta
                switch (previousCluser.clusterSide, currentCluster.clusterSide) {
                case (.bottom, .bottom):
                    // Same side, nothing to do
                    break
                case (.top, .top):
                    // Same side, nothing to do
                    break
                case (.bottom, .top):
                    // Moved from bottom to top
                    lastAction = "\(self.bottomName) to \(self.topName)"
        
                    delta = [
                        self.topName: 1,
                        self.bottomName: -1
                    ]
        
                case (.top, .bottom):
                    // Moved from top to bottom
                    lastAction = "\(self.topName) to \(self.bottomName)"
        
                    delta = [
                        self.topName: -1,
                        self.bottomName: 1
                    ]
                }
                
                return OccupancyChange(action: lastAction, delta: delta)
            }
            .print()
            .assign(to: &$currentDelta)
        
    }
    
    /// Create a Publisher which repeatedly fetches data from the sensor.
    /// - Parameter interval: Time interval at which to refresh
    /// - Returns: A Publisher with time-averaged sensor data
    func sensorPublisher() -> AnyPublisher<SensorPayload?, Never> {
        return Timer.publish(every: refreshInterval, on: .main, in: .common)
            .autoconnect()
            .flatMap { date -> AnyPublisher<SensorPayload, Error> in
                return self.sensorDataPublisher()
            }
            // Average a number of frames together to make the values more stable
            .collect(averageFrameCount)
            .map { buffer -> SensorPayload in
                
                // Create an empty array with the length from the first element
                let emptyArray = Array(repeating: Double.zero, count: buffer[0].rows * buffer[0].cols)
                
                let totals: [Double] = buffer.reduce(emptyArray) { pixelTotal, payload in
                    // Add all the values together
                    return pixelTotal.enumerated().map { index, value in
                        value + payload.rawData[index]
                    }
                }
                
                // Average the values with the frame buffer
                let averageData = totals.map { $0 / Double(self.averageFrameCount) }
                
                // Return the first elemet with the new data
                return SensorPayload(sensor: buffer[0].sensor,
                                     rows: buffer[0].rows,
                                     cols: buffer[0].cols,
                                     data: averageData)
            }
            .catch({ _ in
                Just(nil)
            })
            .eraseToAnyPublisher()
            
    }
    
    func findRelevantPixels(_ data: SensorPayload) -> [Pixel] {
        let threshold = data.mean + deltaThreshold
        
        return data.pixels.filter {
            $0.temp >= threshold
        }
    }
    
    func clusterPixels(_ pixels: [Pixel]) -> [Cluster] {
        var clusters = [Cluster]()
        
        pixels.forEach { pixel in
            if let neighbor = clusters.first(where: { $0.isNeighbored(to: pixel) }) {
                neighbor.pixels.append(pixel)
            } else {
                clusters.append(Cluster(pixel))
            }
        }
        
        return clusters
    }
    
    func clusterPixels(_ data: SensorPayload) -> [Cluster] {
        let pixels = findRelevantPixels(data)
        return clusterPixels(pixels)
    }
}
