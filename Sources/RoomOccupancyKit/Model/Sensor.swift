//
//  Sensor.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/20/21.
//


import Foundation
import OpenCombineShim

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum Room: CustomStringConvertible, Decodable, Hashable, Comparable {
    
    case room(String)
    case æther
    
    public var description: String {
        switch self {
        case let .room(name):
            return name
        case .æther:
            return "Æther"
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        self = .room(try container.decode(String.self))
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }
    
    var slug: String {
        description.slug
    }
    
    var publishStateChanges: Bool {
        switch self {
        case .room:
            return true
        case .æther:
            return false
        }
    }
}

public struct OccupancyChange: CustomStringConvertible {
    
    public static let `default` = OccupancyChange(action: "No Action", delta: [:])
    
    public let action: String
    public let delta: [Room: Int]
    public let absolute: Bool
    
    public init(action: String, delta: [Room: Int], absolute: Bool = false) {
        self.action = action
        self.delta = delta
        self.absolute = absolute
    }

    public var description: String {
        if absolute {
            return "\(action) -> Absolute \(delta)"
        }
        return "\(action) -> \(delta)"
    }
    
    public var hasAction: Bool {
        !delta.isEmpty
    }
}

enum Direction {
    case toTop
    case toBottom
}

public class Sensor: ObservableObject, Identifiable, Decodable {
    public let url: URL
    
    public let topName: Room
    public let bottomName: Room
    
    public var id: URL { url }
    
    public var title: String { "\(topName) / \(bottomName)" }
    
    public var deltaThreshold: Double = 1.5
    public var minClusterSize: Int = 10
    public var averageFrameCount: Int = 2
    public var refreshInterval: TimeInterval = 0.1
    
    public let rows: Int = 8
    public let cols: Int = 8
    
    var tokens: [AnyCancellable] = []
    @Published public var currentState: SensorPayload = SensorPayload(sensor: "Fake Sensor", data: []) {
        didSet {
            print("New Sensor Value Set")
        }
    }
    @Published public var currentCluster: Cluster?
    @Published public var currentDelta: OccupancyChange = OccupancyChange.default
    @Published public var averageTemperature: Double = 21

    let backgroundQueue = DispatchQueue(label: "WebSocketQueue", qos: .utility)

    public init(_ url: URL, topName: Room = .æther, bottomName: Room = .æther) {
        self.url = url
        self.topName = topName
        self.bottomName = bottomName
    }
    
    // MARK: Codable
    public enum CodingKeys: String, CodingKey {
        case url,
             topName,
             bottomName,
             deltaThreshold,
             minClusterSize,
             averageFrameCount,
             refreshInterval

    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Primary Info
        self.url = try container.decode(URL.self, forKey: .url)
        self.topName = try container.decodeIfPresent(Room.self, forKey: .topName) ?? .æther
        self.bottomName = try container.decodeIfPresent(Room.self, forKey: .bottomName) ?? .æther

        // Sensor Config
        self.deltaThreshold = try container.decodeIfPresent(Double.self, forKey: .deltaThreshold) ?? 1.5
        self.minClusterSize = try container.decodeIfPresent(Int.self, forKey: .minClusterSize) ?? 10
        self.averageFrameCount = try container.decodeIfPresent(Int.self, forKey: .averageFrameCount) ?? 2
        self.refreshInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .refreshInterval) ?? 0.1
        
    }
//    
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        
//        // Primary Info
//        try container.encode(url, forKey: .url)
//        try container.encode(topName, forKey: .topName)
//        try container.encode(bottomName, forKey: .bottomName)
//        
//        // Sensor Config
//        try container.encode(deltaThreshold, forKey: .deltaThreshold)
//        try container.encode(minClusterSize, forKey: .minClusterSize)
//        try container.encode(averageFrameCount, forKey: .averageFrameCount)
//        try container.encode(refreshInterval, forKey: .refreshInterval)
//    }
    
    // MARK: - Combine
    
    /// Continually read data from the sensor and update the counts.
    public func monitorData() {
        print("Connecting to \(url)")
        // Create the timer publisher
        let pub = URLSession.shared.webSocketTaskPublisher(for: url)
            .dropFirst() // Drop the welcome message from the socket
            // We only need the string messages
            .compactMap { message in
                switch message {
                case let .string(string):
                    return SensorPayload(sensor: self.title,
                                         rows: self.rows,
                                         cols: self.cols,
                                         data: string)
                case .data:
                    return nil
                @unknown default:
                    return nil
                }
            }
            .replaceError(with: nil)
            .compactMap { $0 }
            .averageFrames(averageFrameCount)
//            .logSensorData()
            .subscribe(on: backgroundQueue)
            .receive(on: RunLoop.main)
            .share()
        
        // Assign to current state
        pub
//            .receive(on: RunLoop.main)
            .assign(to: &$currentState)
        
        pub
            .compactMap { $0.mean }
            .collect(100)
            .map { temps in
                (temps.reduce(0, +) / Double(temps.count)).rounded()
            }
            
            .assign(to: &$averageTemperature)
            
        // Assign to cluster
        pub
            .map { self.clusterPixels($0) }
            .map { $0.largest(minSize: self.minClusterSize) } // Map the clusters to the largest
//            .receive(on: RunLoop.main)
            .assign(to: &$currentCluster)
        
        
        $currentCluster
            .compactMap { $0 } // Skip nil clusters
//            .logGrid()
            .pairwise()
            .parseDelta(currentDelta.action, top: topName, bottom: bottomName)
            .filter { $0.hasAction }
//            .receive(on: RunLoop.main)
            .assign(to: &$currentDelta)
        
    }
    
    
    /// A publisher that fetches data from the sensor.
    /// - Returns: A Publisher with the latest sensor info
    func dataDownloadPublisher() -> AnyPublisher<SensorPayload, Never> {
        URLSession.shared.dataTaskPublisher(for: url)
            .timeout(.milliseconds(100), scheduler: DispatchQueue.main)
            .tryMap { element in
                guard let httpRespone = element.response as? HTTPURLResponse,
                      httpRespone.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                
                return element.data
            }
            .decode(type: SensorPayload?.self, decoder: JSONDecoder())
            .replaceError(with: nil)
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    /// A publisher that fetches data from the sensor.
    /// - Returns: A Publisher with the latest sensor info
    func webSocketPublisher() -> AnyPublisher<SensorPayload, Never> {
        URLSession.shared.dataTaskPublisher(for: url)
            .timeout(.milliseconds(100), scheduler: DispatchQueue.main)
            .tryMap { element in
                guard let httpRespone = element.response as? HTTPURLResponse,
                      httpRespone.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                
                return element.data
            }
            .decode(type: SensorPayload?.self, decoder: JSONDecoder())
            .replaceError(with: nil)
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    /// Create a Publisher which repeatedly fetches data from the sensor.
    /// - Parameter interval: Time interval at which to refresh
    /// - Returns: A Publisher with time-averaged sensor data
    func sensorPublisher() -> AnyPublisher<SensorPayload, Never> {
        return Timer.publish(every: refreshInterval, on: RunLoop.current, in: .common)
            .autoconnect()
            .flatMap { date in
                return self.dataDownloadPublisher()
            }
            .eraseToAnyPublisher()
            
    }
    
    // MARK: - Data Processing
    public func resetSensor() {
        currentDelta = OccupancyChange(action: "Reset", delta: [topName : 0, bottomName: 0], absolute: true)
    }
    
    public func findRelevantPixels(_ data: SensorPayload) -> [Pixel] {
        let threshold = averageTemperature + deltaThreshold
        
        return data.pixels.filter {
            $0.temp >= threshold
        }
    }
    
    public func clusterPixels(_ pixels: [Pixel]) -> [Cluster] {
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
    
    public func clusterPixels(_ data: SensorPayload) -> [Cluster] {
        let pixels = findRelevantPixels(data)
        return clusterPixels(pixels)
    }
}
