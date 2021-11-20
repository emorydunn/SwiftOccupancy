//
//  SensorPayload.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/18/21.
//

import Foundation
import MQTT

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
    
    public func drawImage(pixelSize: Int = 10,
                          minTemperature: Float = 16,
                          maxTemperature: Float = 30) -> CGImage? {
        
        let side = cols * pixelSize

        guard let context = CGContext(data: nil,
                                width: side,
                                height: side,
                                bitsPerComponent: 5,
                                bytesPerRow: 0,
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        else {
            print("Could not make CGContext")
            return nil
        }
        
        stride(from: 0, to: cols, by: 1).forEach { currentPage in
            let verticalOffset = currentPage * pixelSize
            
            let row = rawData[(currentPage * cols)..<(currentPage * cols) + cols]
            
            row.enumerated().forEach { offset, datum in
                
                let rect = CGRect(x: offset * pixelSize,
                                  y: verticalOffset,
                                  width: 10,
                                  height: 10)
                
                let hue = datum.tempColor(minTemperature, maxTemperature)

                context.setFillColor(hue)
                context.fill(rect)


            }
            
        }
        
        return context.makeImage()
        
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
