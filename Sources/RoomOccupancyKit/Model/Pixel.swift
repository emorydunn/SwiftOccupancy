//
//  Pixel.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/20/21.
//

import Foundation

public class Pixel: Identifiable, Hashable, Codable {
    
    public var id: (Int, Int) { (x, y) }
    
    public let x: Int
    public let y: Int
    public let temp: Float
    
    public var tempString: String { "\(Int(temp)) ºc" }
    
    public init(x: Int, y: Int, temp: Float) {
        self.x = x
        self.y = y
        self.temp = temp
    }
    
    public static func == (lhs: Pixel, rhs: Pixel) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y && lhs.temp == rhs.temp
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
        hasher.combine(temp)
    }
    
    /// Normalize the temperature to a value between `0` and `1`
    /// - Parameters:
    ///   - min: Min temp (`0`)
    ///   - max: Max temp (`1`)
    /// - Returns: Normalized temp
    @available(*, deprecated, renamed: "temp.normalize(_:_:)", message: "Use the method on Double.")
    public func normalize(_ min: Float, _ max: Float) -> Float {
        (temp - min) / (max - min)
    }
    
}

extension Pixel: CustomStringConvertible {
    public var description: String {
        "Pixel (\(x), \(y)) \(tempString)"
    }
}

extension Pixel: Comparable {
    public static func < (lhs: Pixel, rhs: Pixel) -> Bool {
        lhs.x < rhs.x && lhs.y < rhs.y
    }
    
    
}

extension Array where Element: Pixel {
    /// Print a textual representation of a grid of pixels.
    ///
    /// ```
    /// [ ][ ][ ][ ][ ][ ][ ][ ]
    /// [ ][ ][ ][ ][ ][ ][ ][ ]
    /// [ ][ ][ ][ ][•][•][•][ ]
    /// [ ][ ][ ][•][•][•][•][ ]
    /// [ ][ ][ ][ ][•][•][•][•]
    /// [ ][ ][ ][ ][•][•][•][•]
    /// [ ][ ][ ][ ][ ][•][•][ ]
    /// [ ][ ][ ][ ][ ][ ][ ][ ]
    /// ```
    ///
    /// - Parameters:
    ///   - columns: Number of columns
    ///   - rows: Number of rows
    func printGrid(columns: Int = 8, rows: Int = 8) {
        let grid = (1...columns).map { y in
            (1...rows).map { x in
                if self.contains(where: { $0.x == x && $0.y == y }) {
                    return "▒▒"
                }
                return "░░"
                
            }.joined(separator: " ")
        }
        
        print(grid.joined(separator: "\n"))
    }
}
