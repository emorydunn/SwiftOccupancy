//
//  Double.swift
//  
//
//  Created by Emory Dunn on 9/7/21.
//

import Foundation

extension Double {
    /// Normalize the temperature to a value between `0` and `1`
    /// - Parameters:
    ///   - min: Min temp (`0`)
    ///   - max: Max temp (`1`)
    /// - Returns: Normalized temp
    public func normalize(_ min: Double, _ max: Double) -> Double {
        (self - min) / (max - min)
    }

    public func temp(_ min: Double, _ max: Double) -> Int {
        let hue = normalize(min, max) * 360
        
        var newHue = hue + 90
        if newHue > 360 {
            newHue -= 360
        }
        
        return Int(newHue)
    }

}

extension Float {
    /// Normalize the temperature to a value between `0` and `1`
    /// - Parameters:
    ///   - min: Min temp (`0`)
    ///   - max: Max temp (`1`)
    /// - Returns: Normalized temp
    public func normalize(_ min: Float, _ max: Float) -> Float {
        (self - min) / (max - min)
    }

    public func temp(_ min: Float, _ max: Float) -> Int {
        let hue = normalize(min, max) * 360
        
        var newHue = hue + 90
        if newHue > 360 {
            newHue -= 360
        }
        
        return Int(newHue)
    }

}
