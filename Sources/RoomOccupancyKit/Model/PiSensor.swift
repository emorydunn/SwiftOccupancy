//
//  PiSensor.swift
//  
//
//  Created by Emory Dunn on 9/12/21.
//

import Foundation
import MQTT
import AMG88xx
import SwiftyGPIO
import OpenCombineShim

public class PiSensor: Decodable {
    public var topRoom: Room = .æther
    public var bottomRoom: Room = .æther
    
    public var deltaThreshold: Float
    public var minClusterSize: Int
    public var minWidth: Int
    public var minHeight: Int
    public var averageFrameCount: Int
    
    public enum CodingKeys: String, CodingKey {
        case topRoom, bottomRoom
        case deltaThreshold
        case minClusterSize
        case minWidth
        case minHeight
        case averageFrameCount
    }
    
    public init(topRoom: Room,
                bottomRoom: Room,
                deltaThreshold: Float = 2,
                minClusterSize: Int = 10,
                minWidth: Int = 3,
                minHeight: Int = 3,
                averageFrameCount: Int = 2) {
        
        self.topRoom = topRoom
        self.bottomRoom = bottomRoom
        self.deltaThreshold = deltaThreshold
        self.minClusterSize = minClusterSize
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.averageFrameCount = averageFrameCount
    }
    
    @Published public var sensorData: SensorPayload?
    @Published public var currentCluster: Cluster?
    @Published public var averageTemp: Float = 22.0
    
    @Published public var topRoomCount: Int = 0
    @Published public var bottomRoomCount: Int = 0
    
    var tokens: [AnyCancellable] = []
    
    public func monitorRooms(from client: MQTTClient) {
        topRoom
            .subscribe(with: client)
            .replaceError(with: 0)
            .assign(to: &$topRoomCount)
        
        $topRoomCount
            .removeDuplicates()
            .sink { value in
                self.topRoom.publishState(value, with: client)
            }
            .store(in: &tokens)

        bottomRoom
            .subscribe(with: client)
            .replaceError(with: 0)
            .assign(to: &$bottomRoomCount)
        
        $bottomRoomCount
            .removeDuplicates()
            .sink { value in
                self.bottomRoom.publishState(value, with: client)
            }
            .store(in: &tokens)
    }
    
    public func monitorSensor(on interface: I2CInterface) {
        // Create the sensor
        let sensor = AMG88(interface)
        
        // Monitor the sensor
        Timer
            .publish(every: 0.1, on: .main, in: .default)
            .map { _ in
                sensor.readPixels()
            }
            // Map to SensorPayload
            .map { pixels in
                SensorPayload(sensor: "", data: pixels)
            }
            .breakpointOnError()
            .replaceError(with: nil)
            .averageFrames(averageFrameCount)
            .assign(to: &$sensorData)
        
        // Collect rolling average temp
        $sensorData
            .compactMap { $0 }
            .compactMap { $0.mean }
            .collect(100)
            .map { temps in
                (temps.reduce(0, +) / Float(temps.count)).rounded()
            }
            .assign(to: &$averageTemp)
        
        $sensorData
            .compactMap { $0 }
            .findRelevantPixels(averageTemperature: averageTemp, deltaThreshold: deltaThreshold)
            .clusterHotestPixels()
            .map {
                guard let cluster = $0 else { return nil }
                
                // Ensure the cluster meets the min size
                guard cluster.size >= self.minClusterSize else {
                    return nil
                }
                
                let box = cluster.boundingBox()
                let width = box.maxX - box.minX
                let height = box.maxY - box.minY

                // Ensure the cluser has minimum dimensions
                guard width >= self.minWidth && height >= self.minWidth else {
                    return nil
                }

                return cluster
            }
            .assign(to: &$currentCluster)
        
        $currentCluster
            .compactMap { $0 }
            .logGrid()
            .pairwise()
            .parseDelta(top: topRoom, bottom: bottomRoom)
            .sink { change in
                switch change.direction {
                case .toTop:
                    self.topRoomCount += 1
                    self.bottomRoomCount = max(0, self.bottomRoomCount - 1)
                case .toBottom:
                    self.topRoomCount = max(0, self.topRoomCount - 1)
                    self.bottomRoomCount += 1
                }
            }
            .store(in: &tokens)
        
    }

}
