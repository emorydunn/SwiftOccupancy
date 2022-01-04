//
//  CounterOptions.swift
//  
//
//  Created by Emory Dunn on 1/2/22.
//

import Foundation
import ArgumentParser
import RoomOccupancyKit

struct CounterOptions: ParsableArguments {
    @Option(name: .customLong("delta"), help: "The delta between what is detected as foreground and background.")
    var deltaThreshold: Float = 2
    
    @Option(name: .customLong("size"), help: "The minimum number of pixels for a cluster to be included.")
    var minClusterSize: Int = 5
    
    @Option(name: .customLong("width"), help: "The minimum width of a cluster's bounding box.")
    var minWidth: Int = 3
    
    @Option(name: .customLong("height"), help: "The minimum height of a cluster's bounding box.")
    var minHeight: Int = 2
    
    func configureCounter(_ counter: OccupancyCounter) {
        counter.deltaThreshold = deltaThreshold
        counter.minWidth = minWidth
        counter.minHeight = minHeight
        counter.minClusterSize = minClusterSize
    }
}
