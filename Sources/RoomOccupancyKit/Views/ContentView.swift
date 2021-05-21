//
//  ContentView.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/16/21.
//

import SwiftUI
import Combine

struct ContentView: View {
    
    @ObservedObject var manager: SensorManager
    @State var overviewActive: Bool = false

    var body: some View {
        
        NavigationView {
            List {
                Section(header: Text("Rooms")) {
                    ForEach(manager.occupancy.sorted(by: { $0.key < $1.key }), id: \.key) { room in
                        HStack {
                            Text(room.key.description)
                            Spacer()
                            Text(String(format: "%0d", room.value))
                        }
                    }
                }
                
//                NavigationLink("Overview",
//                               destination: SensorOverviewView(manager: manager),
//                               isActive: $overviewActive)
                
                Section(header: Text("Sensors")) {
                    ForEach(manager.sensors) { sensor in
                        NavigationLink(sensor.title, destination: SensorView(sensor: sensor))
                    }
                }
            }
            .navigationTitle("Occupancy")
        }
        .onAppear {
            manager.monitorSensors()
        }
        .toolbar {
            ToolbarItem {
                Button("Reset Sensors") {
                    NSLog("Resetting All Sensors")
                    manager.sensors.forEach {
                        $0.resetSensor()
                    }
                }
            }
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(manager: SensorManager(sensors: [
            Sensor(URL(string: "http://10.0.2.163/raw")!,
                   topName: .room("Hall"),
                   bottomName: .room("Office"))
        ],
        haConfig: HAConfig(url: URL(string: "homeassistant.local")!, token: "")
        ))
    }
}
