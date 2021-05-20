//
//  SwiftUIView.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/18/21.
//

import SwiftUI

struct SensorView: View {
    
    @ObservedObject var sensor: Sensor
    
    var body: some View {
        
        Group {
            if let data = sensor.currentState {
                VStack(alignment: .center) {
                    
                    Text(sensor.currentDelta.action)
                        .font(.title)

                    if let cluster = sensor.currentCluster {
                        HStack {
                            Text(cluster.clusterSide.rawValue.capitalized)
                                .font(.headline)
                            Text(verbatim: "Center: \(cluster.center)")
                                .font(.subheadline)
                        }
                        
                    } else {
                        Text("No Clusters")
                            .font(.headline)
                    }
                    
                    
                    HStack {
                        Text("Rolling: \(sensor.averageTemperature) ºc")
                        Spacer()
                        Text("Mean: \(data.mean) ºc")
                    }
                    Spacer()

                    ThermalImageView(data: data, cluster: sensor.currentCluster)
                        .aspectRatio(contentMode: .fit)
                    
                    Spacer()
                    
                    Stepper(value: $sensor.deltaThreshold, in: 0...5, step: 0.5) {
                        Text("Delta Threshold")
                        Spacer()
                        Text("\(sensor.deltaThreshold)")
                    }
                    Stepper(value: $sensor.minClusterSize, in: 1...10, step: 1) {
                        Text("Min Cluster Size")
                        Spacer()
                        Text("\(sensor.minClusterSize)")
                    }
                    Stepper(value: $sensor.averageFrameCount, in: 1...5, step: 1) {
                        Text("Frames to Average")
                        Spacer()
                        Text("\(sensor.averageFrameCount)")
                    }

                    HStack {
                        Button("Reset Sensor") {
                            NSLog("Resetting \(sensor.title)")
                            sensor.resetSensor()
                        }
                        Spacer()
                        Button("Log Frame") {
                            data.logData()
                        }
                    }
                    
                }
                
            } else {
                ProgressView("Loading values")
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(width: 50.0 * 8, height: 50.0 * 8)
                
            }
        }
        
        .padding()
        .navigationTitle(sensor.title)

    }
}

struct SensorView_Previews: PreviewProvider {
    static var previews: some View {
        SensorView(sensor: Sensor(URL(string: "http://10.0.2.163/raw")!,
                                  topName: "Hall",
                                  bottomName: "Office"))
    }
}
