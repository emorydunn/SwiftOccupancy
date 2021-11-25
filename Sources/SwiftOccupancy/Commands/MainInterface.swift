//
//  File.swift
//  
//
//  Created by Emory Dunn on 11/23/21.
//

import Foundation
import ArgumentParser

@main
struct SwiftOccupancy: ParsableCommand {
    static var configuration = CommandConfiguration(
                                                    abstract: "Read occupancy from an AMG88 sensor.",
                                                    discussion: "Read and parse data from an AMG88 sensor and publish occupancy changes via MQTT.",
                                                    version: "0.1.",
                                                    shouldDisplay: true,
                                                    subcommands: [
                                                        OccupancyCommand.self,
                                                        MQTTPublisher.self,
                                                        LogDataCommand.self
                                                    ]
    )
}
