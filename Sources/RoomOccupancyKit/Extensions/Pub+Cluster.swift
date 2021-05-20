//
//  Publisher.swift
//  ThermalViewerTests
//
//  Created by Emory Dunn on 5/19/21.
//

import Foundation
import OpenCombineShim

extension Publisher where Output == Cluster, Failure == Never {
    
    func logGrid() -> AnyPublisher<Cluster, Never> {
        self.map { cluster in
            cluster.printGrid()
            return cluster
        }
        .eraseToAnyPublisher()
    }
    
}

extension Publisher where Output == (Cluster, Cluster), Failure == Never {
    
    func parseDelta(_ previousAction: String, top: String, bottom: String) -> AnyPublisher<OccupancyChange, Never> {
        return self.map { (previousCluser, currentCluster) -> OccupancyChange in
            var delta = [String: Int]()
            var lastAction = previousAction
            
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
                lastAction = "\(bottom) to \(top)"
                
                delta = [
                    top: 1,
                    bottom: -1
                ]
                
            case (.top, .bottom):
                // Moved from top to bottom
                lastAction = "\(top) to \(bottom)"
                
                delta = [
                    top: -1,
                    bottom: 1
                ]
            }
            
            return OccupancyChange(action: lastAction, delta: delta)
        }
        .eraseToAnyPublisher()
    }
    
}
