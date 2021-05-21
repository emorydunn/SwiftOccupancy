//
//  ThermalViewerApp.swift
//  Shared
//
//  Created by Emory Dunn on 5/16/21.
//

#if canImport(SwiftUI)
import SwiftUI

@main
struct ThermalViewerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(manager: SensorManager(sensors: [
                Sensor(URL(string: "http://10.0.2.163/raw")!,
                       topName: "Hall",
                       bottomName: "Office")
            ]))
        }
    }
}
#endif
