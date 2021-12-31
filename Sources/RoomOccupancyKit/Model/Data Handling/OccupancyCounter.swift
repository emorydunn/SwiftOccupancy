//
//  OccupancyCounter.swift
//  
//
//  Created by Emory Dunn on 11/22/21.
//

import Foundation
import MQTT

/// An `OccupancyCounter` consumes a stream of data from an AMGSensor
/// and produces a stream of occupancy changes.
public class OccupancyCounter {
    
    public var id: String {
        "\(topRoom)-\(bottomRoom)"
    }
    
    let sensor: AMGSensorProtocol
    
    public var topRoom: Room = .æther
    public var bottomRoom: Room = .æther
    
    public var deltaThreshold: Float = 2
    
    public var minClusterSize: Int = 10
    public var minWidth: Int = 3
    public var minHeight: Int = 3
    
    public var averageFrameCount: Int = 2
    
    // Counts
    public var topRoomCount: Int = 0
    public var bottomRoomCount: Int = 0
    
    var currentCluster: Cluster?
    @Buffer(count: 5)
    internal var previousCluster: Cluster?
    
    init(sensor: AMGSensorProtocol, topRoom: Room = .æther, bottomRoom: Room = .æther) {
        self.sensor = sensor
        self.topRoom = topRoom
        self.bottomRoom = bottomRoom
    }
    
    /// Cluster the pixels in the specified data, filtering for size requirements
    /// - Parameter data: The `SensorPayload` to cluster
    /// - Returns: A `Cluster`
    func clusterPixels(in data: SensorPayload) throws -> Cluster? {
        
        // Cluster the pixels around hottest pixel
        let cluster = Cluster(from: data, deltaThreshold: deltaThreshold)
        
        // Ensure the cluster meets our requirements
        guard
            cluster.size >= minClusterSize &&
                cluster.boundingBox.width >= minWidth &&
                cluster.boundingBox.height >= minHeight
        else {
            return nil
        }
        
        return cluster
    }
    
    /// Determine changes in based on clusters in the data.
    /// - Parameter data: Data to cluster
    /// - Returns: Any changes found
    @discardableResult
    func countChanges(using data: SensorPayload) throws -> OccupancyChange? {
        currentCluster = try self.clusterPixels(in: data)
        
        currentCluster?.printGrid()
        
        var change: OccupancyChange?
        if let currentCluster = currentCluster, let previousCluster = previousCluster {
            change = OccupancyChange(currentCluster: currentCluster,
                            previousCluster: previousCluster,
                            topRoom: topRoom,
                            bottomRoom: bottomRoom)
            
            change?.update(topCount: &topRoomCount, bottomCount: &bottomRoomCount)
        }
        
        // Set the previous cluster to the current cluster
        previousCluster = currentCluster
        
        return change
    }

    /// Subscribe to the MQTT topics for each room and update the room counts
    /// - Parameter client: The MQTT client to use.
    func subscribeToMQTTCounts(with client: AsyncMQTTClient) async {
        Task {
            try await updateCount(for: topRoom,
                           count: &topRoomCount,
                           onStream: client.streamSubscription(topic: topRoom.stateTopic, qos: .atLeastOnce))
        }
        
        Task {
            try await updateCount(for: bottomRoom,
                           count: &bottomRoomCount,
                           onStream: client.streamSubscription(topic: bottomRoom.stateTopic, qos: .atLeastOnce))
        }
    }
    
    /// Publish a change in occupancy to MQTT
    /// - Parameters:
    ///   - change: The change
    ///   - client: The client
    func publishChange(_ change: OccupancyChange, with client: AsyncMQTTClient) {
        print("Publishing \(change) to MQTT")
        
        topRoom.publishState(topRoomCount, with: client.client)
        bottomRoom.publishState(bottomRoomCount, with: client.client)
    }
    
    /// Watch an MQTT stream and update the occupancy counts
    /// - Parameters:
    ///   - room: The room to watch
    ///   - count: The count to update
    ///   - stream: The stream to observe
    func updateCount(for room: Room, count: inout Int, onStream stream: AsyncThrowingStream<PublishPacket, Error>) async throws {
        print("Subscribing to \(room) count")
        for try await message in stream {
            if
                let string = String(data: message.payload, encoding: .utf8),
                let num = Int(string) {
                print("Updating \(room) to \(num)")
                count = num
            }
        }
    }
    
    /// Reset the counts for both rooms to zero.
    /// - Parameter client: The MQTT client to publish the reset to.
    public func resetRoomCounts(with client: AsyncMQTTClient) {
        print("Resetting \(topRoom) Count")
        topRoomCount = 0
        topRoom.publishState(topRoomCount, with: client.client)
        
        print("Resetting \(bottomRoom) Count")
        bottomRoomCount = 0
        bottomRoom.publishState(bottomRoomCount, with: client.client)
    }

}
