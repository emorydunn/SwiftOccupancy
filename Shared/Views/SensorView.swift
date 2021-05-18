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
                    Spacer()

                    ThermalImageView(data: data, clusters: sensor.currentClusters)
                        .aspectRatio(contentMode: .fit)
                    
                    Spacer()

                    HStack {
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
