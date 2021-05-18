//
//  SensorPayload.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/18/21.
//

import Foundation

public struct SensorPayload: Decodable {
    public let sensor: String
    public let rows: Int
    public let cols: Int
    public let data: [[Pixel]]
    public let pixels: [Pixel]
    public let rawData: [Double]
    
    public let mean: Double
    
    public enum CodingKeys: String, CodingKey {
        case sensor, rows, cols, data
    }
    
    public init(sensor: String, rows: Int = 8, cols: Int = 8, data: [Double]) {
        self.sensor = sensor
        self.rows = rows
        self.cols = cols
        
        var tempTotal: Double = 0
        var pixels = [Pixel]()
        
        
        let arrayData: [[Pixel]] = (0..<cols).map { offset in
            let row = data[0 + offset * rows..<rows + offset * rows]
            
            return row.enumerated().map { index, value in
                tempTotal += value
                let p = Pixel(x: index + 1, y: offset + 1, temp: value)
                pixels.append(p)
                return p
            }
        }
        
        self.rawData = data
        self.data = arrayData
        self.pixels = pixels
        
        self.mean = tempTotal / Double(rawData.count)
    }
    
    public init(sensor: String, rows: Int = 8, cols: Int = 8, data: String) {
        
        let rawData = data
            .components(separatedBy: ",")
            .compactMap { Double($0) }
        
        self.init(sensor: sensor,
                  rows: rows,
                  cols: cols,
                  data: rawData)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.init(sensor: try container.decode(String.self, forKey: .sensor),
                  rows: try container.decode(Int.self, forKey: .cols),
                  cols: try container.decode(Int.self, forKey: .cols),
                  data: try container.decode(String.self, forKey: .data))
    }
    
    public func logData() {
        print("FrameData:", rawData.map { String($0) }.joined(separator: ","))
    }
    
}
