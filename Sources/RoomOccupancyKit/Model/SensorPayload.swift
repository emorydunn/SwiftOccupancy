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

    public let rows: Int
    public let cols: Int

    public let pixels: [Pixel]
    public let rawData: [Float]
    
    public let mean: Float
    
    public enum CodingKeys: String, CodingKey {
        case rows, cols, rawData
    }
    
    public init(rows: Int = 8, cols: Int = 8, data: [Float]) throws {
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
        self.pixels = pixels
        
        self.mean = tempTotal / Float(rawData.count)
    }
    
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
                  data: rawData)
    }
    
    public init(rows: Int = 8, cols: Int = 8, data: Data) throws {

        guard let rawData = String(data: data, encoding: .utf8) else {
            throw SensorError.decodingError(encoding: .utf8)
        }
        
        try self.init(
                  rows: rows,
                  cols: cols,
                  data: rawData)
    }

    public func logData() {
        print("FrameData:", rawData.map { String($0) }.joined(separator: ","))
    }
    
    public func createImage(columns: Int = 8,
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
                let hue: Int = datum.temp(minTemperature, maxTemperature)
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
                          pixelSize: Int = 1,
                          minTemperature: Float = 16,
                          maxTemperature: Float = 30) throws -> Surface {
        
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
                
                let hue = datum.tempColor(minTemperature, maxTemperature)

                context.fillColor = hue
                context.addRect(rect)
                context.fillPath()

            }
            
        }
        
        if let cluster = cluster {
            print("Drawing cluster")
            let box = cluster.boundingBox()
            let rect = CGRect(x: box.minX,
                              y: box.minY,
                              width: box.maxX - box.minX,
                              height: box.maxY - box.minY)
            
            context.lineWidth = 10
            context.strokeColor = CGColor.white
            context.strokePath()
        }
        
        context.scaleBy(x: 10, y: 10)
        return context.surface
        
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let rows = try container.decode(Int.self, forKey: .rows)
        let cols = try container.decode(Int.self, forKey: .cols)
        let rawData = try container.decode([Float].self, forKey: .rawData)
        
        self = try SensorPayload(rows: rows, cols: cols, data: rawData)
        
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
