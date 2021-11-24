//
//  SensorPayload.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/18/21.
//

import Foundation
import MQTT
import Silica
import Cairo

#if canImport(FoundationXML)
import FoundationXML
#endif

public enum SensorError: Error {
    case wrongCount(rows: Int, columns: Int, dataCount: Int)
    case decodingError(encoding: String.Encoding)
}

public struct SensorPayload: Codable {
    
    // MARK: Sensor Properties
    /// Number of rows that make up the image
    public let rows: Int
    
    /// Number of columns that make up the image
    public let cols: Int

    /// The raw sensor data
    public let rawData: [Float]
    
    /// The thermistor temperature
    public let thermistorTemperature: Float
    
    // MARK: Derived Properties
    
    /// The parsed pixel data for the sensor
    public let pixels: [Pixel]
    
    /// The average pixel temperature.
    public let mean: Float
    
    public enum CodingKeys: String, CodingKey {
        case rows, cols, rawData, thermistorTemperature
    }
    
    public init(rows: Int = 8, cols: Int = 8, data: [Float], thermistorTemperature: Float) throws {
        self.rows = rows
        self.cols = cols
        
        // Validate the data
        guard data.count == rows * cols else {
            throw SensorError.wrongCount(rows: rows, columns: cols, dataCount: data.count)
        }
        
        var tempTotal: Float = 0
        var pixels = [Pixel]()
        
        (0..<cols).forEach { offset in
            let row = data[(0 + offset * rows)..<(rows + offset * rows)]
            
            row.enumerated().forEach { index, value in
                tempTotal += value
                let p = Pixel(x: index + 1,
                              y: offset + 1,
                              temp: value)
                pixels.append(p)
            }
        }
        
        self.rawData = data
        self.thermistorTemperature = thermistorTemperature
        self.pixels = pixels
        
        self.mean = tempTotal / Float(rawData.count)
    }
    
    @available(*, deprecated)
    public init(rows: Int = 8, cols: Int = 8, data: String) throws {

        // The data is returned in 4 byte temperature chunks: 31.8
        guard data.count == rows * cols * 4 else {
            throw SensorError.wrongCount(rows: rows, columns: cols, dataCount: data.count)
        }
        let rawData: [Float] = stride(from: 0, to: data.count, by: 4).map { offset -> String in
            let chunkStart = data.index(data.startIndex, offsetBy: offset)
            let chunkEnd = data.index(chunkStart, offsetBy: 4)
            
            return String(data[chunkStart..<chunkEnd])
        }
        .compactMap { temp in
            return Float(temp)?.rounded()
        }

        try self.init(
                  rows: rows,
                  cols: cols,
                  data: rawData,
                  thermistorTemperature: 0
        )
    }
    
    @available(*, deprecated)
    public init(rows: Int = 8, cols: Int = 8, data: Data) throws {

//        guard let rawData = String(data: data, encoding: .utf8) else {
//            throw SensorError.decodingError(encoding: .utf8)
//        }
        
        fatalError("This init is deprecated")
//        try self.init(
//                  rows: rows,
//                  cols: cols,
//                  data: rawData,
//                  thermistorTemperature: 0)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let rows = try container.decode(Int.self, forKey: .rows)
        let cols = try container.decode(Int.self, forKey: .cols)
        let rawData = try container.decode([Float].self, forKey: .rawData)
        let therm = try container.decode(Float.self, forKey: .thermistorTemperature)
        
        self = try SensorPayload(rows: rows, cols: cols, data: rawData, thermistorTemperature: therm)
        
    }
    
    // MARK: Methods

    public func logData() {
        print("FrameData:", rawData.map { String($0) }.joined(separator: ","))
    }
    
    static let gradient: [Float: Color] = [
        0.0:    Color(red: 15,  green: 12,  blue: 33),
        0.16:   Color(red: 60,  green: 25,  blue: 142),
        0.32:   Color(red: 185, green: 55,  blue: 168),
        0.48:   Color(red: 233, green: 128, blue: 62),
        0.64:   Color(red: 242, green: 175, blue: 76),
        0.8:    Color(red: 251, green: 220, blue: 89),
        1:      Color(red: 255, green: 255, blue: 255),
    ]
    
    public func drawSVG(columns: Int = 8,
                            pixelSize: Int = 10,
                            minTemperature: Float = 16,
                            maxTemperature: Float = 30) -> String {
        let side = columns * pixelSize
        
        let svg = XMLElement(kind: .element)
        
        svg.name = "svg"
        svg.addAttribute(side, forKey: "width")
        svg.addAttribute(side, forKey: "height")
        svg.addAttribute("http://www.w3.org/2000/svg", forKey: "xmlns")

        stride(from: 0, to: columns, by: 1).forEach { currentPage in
            let verticalOffset = currentPage * pixelSize
            
            let row = rawData[(currentPage * columns)..<(currentPage * columns) + columns]
            
            row.enumerated().forEach { offset, datum in
                let element = XMLElement(name: "rect")
                
                element.addAttribute(offset * pixelSize, forKey: "x")
                element.addAttribute(verticalOffset, forKey: "y")
                element.addAttribute(pixelSize, forKey: "width")
                element.addAttribute(pixelSize, forKey: "height")
                let hue: Int = datum.mapHue(minTemperature, maxTemperature)
                element.addAttribute("hsl(\(hue), 100%, 50%)", forKey: "fill")
                svg.addChild(element)

            }
            
        }
        
        let doc = XMLDocument(rootElement: svg)
        
        doc.characterEncoding = "UTF-8"
        doc.isStandalone = false
        doc.documentContentKind = .xml
        doc.version = "1.0"
        
        return doc.xmlString(options: [.documentTidyXML, .nodePrettyPrint])

    }
    
    public func drawImage(cluster: Cluster?,
                          pixelSize: Int = 15,
                          minTemperature: Float = 16,
                          maxTemperature: Float = 35) throws -> Surface {
        
        let side = cols * pixelSize
        let size = CGSize(width: side, height: side)
        
        let surface = try Surface.Image.init(format: ImageFormat.argb32, width: side, height: side)
        let context = try Silica.CGContext(surface: surface, size: size)
        
        stride(from: 0, to: cols, by: 1).forEach { currentPage in
            let verticalOffset = currentPage * pixelSize
            
            let row = rawData[(currentPage * cols)..<(currentPage * cols) + cols]
            
            row.enumerated().forEach { offset, datum in
                let x = offset * pixelSize
                let y = verticalOffset
                
                let rect = CGRect(x: x,
                                  y: y,
                                  width: pixelSize,
                                  height: pixelSize)
                
//                let hue = datum.tempColor(minTemperature, maxTemperature)
                let color = datum.mapColor(into: SensorPayload.gradient, minTemperature, maxTemperature)

                context.fillColor = color.cgColor
                context.addRect(rect)
                context.fillPath()

            }
            
        }
        
        if let cluster = cluster {
            print("Drawing cluster")
            let box = cluster.boundingBox
            let rect = CGRect(x: box.minX * pixelSize,
                              y: box.minY * pixelSize,
                              width: (box.maxX - box.minX) * pixelSize,
                              height: (box.maxY - box.minY) * pixelSize)
            
            context.lineWidth = 2
            context.strokeColor = CGColor.white
            context.addRect(rect)
            context.strokePath()
        }
        
//        context.scaleBy(x: 10, y: 10)
        return context.surface
        
    }
    
}

extension SensorPayload: CustomStringConvertible {
    public var description: String {
        "Sensor Data \(mean) ºc"
    }
}

extension SensorPayload: DataEncodable {
    public func encode() -> Data {
        try! JSONEncoder().encode(self)
    }
}
