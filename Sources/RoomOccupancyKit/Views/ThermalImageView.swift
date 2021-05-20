//
//  ThermalImageView.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/16/21.
//

import SwiftUI

struct ThermalImageView: View {
    
    let data: SensorPayload
    let cluster: Cluster?
    
    let minTemperature: Double = 16
    let maxTemperature: Double = 30
    
    var body: some View {
        GeometryReader { reader in
            VStack(spacing: 0) {
                ForEach(data.data, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(row, id: \.self) { pixel in
                            ZStack {
                                Rectangle()
                                    .fill(Color(hue: pixel.normalize(minTemperature, maxTemperature),
                                                saturation: 1,
                                                brightness: 0.75))
                                    .hueRotation(Angle(degrees: 90))
                                  
                                VStack {
                                    Text("\(pixel.x), \(pixel.y)")
                                        .fontWeight(.thin)
                                        .foregroundColor(.white)
                                    if let cluster = cluster, cluster.center == pixel {
                                        Text(cluster.clusterSide.rawValue)
                                            .fontWeight(clusterFont(pixel))
                                            .foregroundColor(.white)
                                    } else {
                                        Text(pixel.tempString)
                                            .fontWeight(clusterFont(pixel))
                                            .foregroundColor(.white)
                                    }
                                }
                                
                            }

                            .frame(width: reader.size.width / CGFloat(data.cols))
                            .border(clusterColor(pixel), width: 2)
  
                        }
                        
                    }
                }
   
            }
        }
        .navigationTitle(data.sensor)
    }
    
    func clusterFont(_ pixel: Pixel) -> Font.Weight {
        guard let cluster = cluster, cluster.contains(pixel) else {
            return Font.Weight.regular
        }

        if cluster.center == pixel {
            return Font.Weight.black
        }
        return Font.Weight.regular
    }
    
    func clusterColor(_ pixel: Pixel) -> Color {
        guard let cluster = cluster, cluster.contains(pixel) else {
            return Color.clear
        }

        return Color.white
    }
}

struct ThermalImageView_Previews: PreviewProvider {
    static let sensor = Sensor(URL(string: "localhost")!)
    
    static let frame0 = SensorPayload(sensor: "AMG8833", data: "19.75,20.0,20.75,20.5,20.25,20.5,21.0,21.75,19.75,20.75,20.5,20.5,20.5,20.75,20.75,21.25,20.75,20.5,20.0,20.75,21.0,21.0,21.0,21.75,20.25,20.5,20.25,20.75,21.0,21.25,21.0,21.75,21.0,20.0,21.0,21.25,20.25,20.25,20.5,21.5,20.25,20.25,20.5,21.0,21.0,20.75,21.25,22.25,20.5,20.25,20.75,20.5,20.5,20.25,21.25,23.0,20.5,19.75,20.25,20.5,20.5,21.25,20.75,21.25")
    static let frame1 = SensorPayload(sensor: "AMG8833", data: "20.5,20.5,21.25,20.75,20.25,20.75,21.25,21.5,20.25,21.25,21.0,20.25,21.0,21.25,20.75,21.5,20.5,20.5,21.0,21.75,22.75,21.25,21.75,21.75,20.5,20.5,20.75,21.0,23.25,21.75,21.5,22.75,21.75,20.75,22.75,23.0,23.5,24.0,21.5,21.75,21.75,23.0,26.0,26.25,26.25,26.25,22.0,22.5,22.25,26.25,29.25,29.0,27.5,26.0,22.5,23.5,22.25,26.0,27.75,29.25,27.25,23.5,21.75,21.75")
    static let frame2 = SensorPayload(sensor: "AMG8833", data: "21.5,23.0,26.75,27.75,27.25,27.0,22.75,22.0,20.75,22.5,25.75,26.25,27.5,25.0,21.25,21.5,20.5,21.0,21.5,23.0,24.5,22.0,22.0,21.75,20.5,21.0,20.75,21.0,21.5,21.0,21.5,22.75,21.0,20.0,21.0,21.5,20.75,21.25,21.0,21.75,20.75,20.0,21.0,20.75,21.0,21.25,21.5,22.25,20.0,20.5,20.5,20.25,20.75,20.5,21.5,23.0,19.5,20.0,20.75,20.75,20.75,21.25,20.5,22.0")
    static let frame3 = SensorPayload(sensor: "AMG8833", data: "20.75,20.75,21.25,21.5,21.0,23.25,22.0,22.0,21.0,21.75,22.0,22.75,22.75,23.75,22.0,22.25,21.25,21.75,24.75,26.5,26.75,26.25,23.5,23.0,21.0,22.25,25.75,26.25,26.25,25.75,23.75,22.75,21.75,23.75,26.25,26.5,25.75,26.25,24.0,22.0,21.75,21.75,25.25,25.75,25.75,27.25,24.0,23.25,20.75,21.25,22.0,23.25,23.0,22.5,22.5,23.75,20.75,20.75,20.5,21.75,21.0,22.0,21.0,22.5")
    
    static var previews: some View {
        
//        ThermalImageView(data: frame0,
//                         clusters: sensor.clusterPixels(frame0))
//        ThermalImageView(data: frame1,
//                         clusters: sensor.clusterPixels(frame1))
//        ThermalImageView(data: frame2,
//                         clusters: sensor.clusterPixels(frame2))
        ThermalImageView(data: frame3,
                         cluster: sensor.clusterPixels(frame3).largest(minSize: 7))
    }
}
