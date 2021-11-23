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
    
    var countChanges: AsyncThrowingStream<OccupancyChange, Error> {
        AsyncThrowingStream { continuation in
            Task {
                var previousCluster: Cluster?

                do {
                    for try await data in sensor.data {

                        let cluster = try self.clusterPixels(in: data)
                        
                        cluster?.printGrid()
                        
//                        // If there's no previous cluster
//                        // assign the new cluster and wait for the next frame
//                        if previousCluster == nil {
//                            previousCluster = cluster
//                        }
                        
                        if let currentCluster = cluster, let previousCluster = previousCluster {
                            let change = OccupancyChange(currentCluster: currentCluster,
                                            previousCluster: previousCluster,
                                            topRoom: topRoom,
                                            bottomRoom: bottomRoom)
                            
                            continuation.yield(change)
                        } else {
                            previousCluster = cluster
                        }
                        

                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func updateChanges() async throws {
        for try await change in countChanges {
            change.update(topCount: &topRoomCount, bottomCount: &bottomRoomCount)
        }
    }
    
    func publishChanges(to client: AsyncMQTTClient) async throws {

        Task {
            try await updateCount(for: topRoom,
                           count: &topRoomCount,
                           onStream: client.subscribe(topic: topRoom.stateTopic, qos: .atLeastOnce))
        }
        
        Task {
            try await updateCount(for: bottomRoom,
                           count: &bottomRoomCount,
                           onStream: client.subscribe(topic: bottomRoom.stateTopic, qos: .atLeastOnce))
        }
        
        
        print("Publishing occupancy changes to MQTT")
        for try await change in countChanges {
            change.update(topCount: &topRoomCount, bottomCount: &bottomRoomCount)
            
            print("Publishing \(change) to MQTT")
            
            topRoom.publishState(topRoomCount, with: client.client)
            bottomRoom.publishState(bottomRoomCount, with: client.client)
        }
    }
    
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

}
