//
//  SensorPayload.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/18/21.
//

import Foundation

public struct SensorPayload {
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
    
    public init?(sensor: String, rows: Int = 8, cols: Int = 8, data: [Double]) {
        self.sensor = sensor
        self.rows = rows
        self.cols = cols
        
        // Validate the data
        guard data.count == rows * cols else {
            self.data = []
            self.pixels = []
            self.rawData = []
            self.mean = 0
            return nil
        }
        
        var tempTotal: Double = 0
        var pixels = [Pixel]()
        
        let arrayData: [[Pixel]] = (0..<cols).map { offset in
            let row = data[(0 + offset * rows)..<(rows + offset * rows)]
            
            return row.enumerated().map { index, value in
                tempTotal += value
                let p = Pixel(x: index + 1,
                              y: offset + 1,
                              temp: value)
                pixels.append(p)
                return p
            }
        }
        
        self.rawData = data
        self.data = arrayData
        self.pixels = pixels
        
        self.mean = tempTotal / Double(rawData.count)
    }
    
    public init?(sensor: String, rows: Int = 8, cols: Int = 8, data: String) {

        // The data is returned in 4 byte temperature chunks: 31.8
        guard data.count == rows * cols * 4 else { return nil }
        let rawData = stride(from: 0, to: data.count, by: 4).map { offset in
            let chunkStart = data.index(data.startIndex, offsetBy: offset)
            let chunkEnd = data.index(chunkStart, offsetBy: 4)
            
            return data[chunkStart..<chunkEnd]
        }
        .compactMap { Double($0)?.rounded() }

//        data.
//        let rawData = data
//            .components(separatedBy: ",")
//            .compactMap { Double($0)?.rounded() }
        
        self.init(sensor: sensor,
                  rows: rows,
                  cols: cols,
                  data: rawData)
    }
    
    public init?(sensor: String, rows: Int = 8, cols: Int = 8, data: Data) {

        guard let rawData = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        self.init(sensor: sensor,
                  rows: rows,
                  cols: cols,
                  data: rawData)
    }
    
//    public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//
//
//        guard let payload = (sensor: try container.decode(String.self, forKey: .sensor),
//                  rows: try container.decode(Int.self, forKey: .cols),
//                  cols: try container.decode(Int.self, forKey: .cols),
//                  data: try container.decode(String.self, forKey: .data))
//    }
    
    public func logData() {
        print("FrameData:", rawData.map { String($0) }.joined(separator: ","))
    }
    
}

extension SensorPayload: CustomStringConvertible {
    public var description: String {
        "\(sensor) Sensor Data \(mean) ºc"
    }
}
