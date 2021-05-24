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
    
    let manager: SensorManager = SensorManager(sensors: [
        
    ], haConfig: .haAddOn)
    
    var body: some Scene {
        WindowGroup {
            ContentView(manager: manager)
        }
    }
}
#endif
