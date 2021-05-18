import Foundation
import SwiftUI

public class Pixel: Identifiable, Hashable, Codable {
    
    public var id: (Int, Int) { (x, y) }
    
    public let x: Int
    public let y: Int
    public let temp: Double
    
    public var tempString: String { "\(Int(temp)) ºc" }
    
    public init(x: Int, y: Int, temp: Double) {
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
    
    func normalize(_ min: Double, _ max: Double) -> Double {
        (temp - min) / (max - min)
    }
    
}
